terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "4.9.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "tf-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-5.10*"]
  }
}

variable "tags" {
  type    = list(string)
  default = ["First", "Second"]
}

######################################
# EC2 INSTANCE
######################################

resource "aws_instance" "instance" {
  ami             = data.aws_ami.tf-ami.id   #"ami-0c02fb55956c7d316"
  instance_type   = "t2.micro"
  count           = 2
  key_name        = "firstkey1"
  security_groups = ["ec2_sg"]
  tags = {
    Name = "Terraform ${element(var.tags, count.index)} Instance"
  }


  provisioner "local-exec" {
    command = "echo http://${self.public_ip} >> public_ip.txt"
  }

  provisioner "local-exec" {
    command = "echo http://${self.private_ip} >> private_ip.txt"

  }
  connection {
    host        = self.public_ip
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("firstkey1.pem")
  }

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y httpd",
      "sudo cd /var/www/html",
      "sudo touch index.html",
      "sudo echo Hello World! > /var/www/html/index.html",
      "sudo systemctl enable httpd",
      "sudo systemctl start httpd"
    ]
  }
}
##################################
# SECURITY GROUP
##################################

resource "aws_security_group" "ec2_sg" {
  name        = "ec2_sg"
  description = "ec2 security group"
  ingress {
    from_port   = 80
    protocol    = "tcp"
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    protocol    = "tcp"
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    protocol    = -1
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

######################################
# OUTPUT
######################################

output "instance-public-ip" {
  value = aws_instance.instance.*.public_ip
}