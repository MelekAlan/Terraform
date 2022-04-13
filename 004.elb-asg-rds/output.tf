output "instance_url" {
  value = "http://${aws_lb.tf_lb.dns_name}"
}