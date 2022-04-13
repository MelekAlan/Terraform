###############
# DATA
###############

data "aws_vpc" "selected" {
  default = true
}

data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }
}
data "aws_ami" "aws-linux" {
  owners      = ["amazon"]
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm*"]
  }
}

############################
# LAUNCH TEMPLATE
############################

resource "aws_launch_template" "tf-lt" {
  name                   = "phonebook-lt"
  instance_type          = "t2.micro"
  key_name               = "firstkey1"
  image_id               = data.aws_ami.aws-linux.id
  vpc_security_group_ids = [aws_security_group.ec2_sg.id]
  depends_on             = [github_repository_file.dbendpoint]
  user_data              = filebase64("userdata.sh")
  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Phonebook App"
    }
  }
}

#######################
# TARGET GROUP
#######################

resource "aws_lb_target_group" "tf_target" {
  name        = "tf-lb-tg"
  port        = 80
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = data.aws_vpc.selected.id
  health_check {
    protocol            = "HTTP"         # default HTTP
    port                = "traffic-port" # default
    unhealthy_threshold = 2              # default 3
    healthy_threshold   = 5              # default 3
    interval            = 20             # default 30
    timeout             = 5              # default 10
  }
}


##############################
# APPLICATION LOAD BALANCER
##############################

resource "aws_lb" "tf_lb" {
  name               = "tf-lb"
  load_balancer_type = "application"
  internal           = false # default true 
  security_groups    = [aws_security_group.elb_sg.id]
  subnets            = data.aws_subnets.public.ids
  ip_address_type    = "ipv4"
}

#############################
# ALB LİSTENER
#############################

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.tf_lb.arn # required
  default_action {                     # required 
    type             = "forward"
    target_group_arn = aws_lb_target_group.tf_target.arn
  }
  port     = "80"
  protocol = "HTTP"
}

###########################
# AUTO SCALING GROUP 
###########################

resource "aws_autoscaling_group" "tf-asg" {
  name                      = "tf-phonebookapp"
  max_size                  = 3
  min_size                  = 1
  desired_capacity          = 1
  health_check_type         = "ELB"
  health_check_grace_period = 300
  target_group_arns         = [aws_lb_target_group.tf_target.arn]
  vpc_zone_identifier       = data.aws_subnets.public.ids
  launch_template {
    id      = aws_launch_template.tf-lt.id
    version = aws_launch_template.tf-lt.latest_version
  }
}

############################
# DATABASE 
###########################

resource "aws_db_instance" "tf_rds" {
  engine                      = "mysql"
  engine_version              = "8.0.19"
  allocated_storage           = 20
  vpc_security_group_ids      = [aws_security_group.db_sg.id]
  allow_major_version_upgrade = false
  auto_minor_version_upgrade  = true
  backup_retention_period     = 0
  monitoring_interval         = 0 # default 0
  port                        = 3306
  publicly_accessible         = false # default false
  skip_final_snapshot         = true  # default true
  instance_class              = "db.t2.micro"
  identifier                  = "tf-phonebook-db"
  db_name                        = "phonebook"
  username                    = "admin"
  password                    = "Melek-tf"

}

#################################
# GİTHUB REPO
################################


resource "github_repository_file" "dbendpoint" {
  content             = aws_db_instance.tf_rds.address
  file                = "dbserver.endpoint"
  repository          = "phonebook"
  overwrite_on_create = true
  branch              = "main"
}