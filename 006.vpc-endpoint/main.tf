##############################
#  VPC ENDPOINT
#############################

resource "aws_vpc_endpoint" "tf-endpoint-s3" {
  vpc_id              = aws_vpc.tf_vpc.id
  service_name        = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type   = "Gateway"
  #policy default full access
}


resource "aws_vpc_endpoint_route_table_association" "ft-route-table" {
  route_table_id = aws_route_table.private.id
  vpc_endpoint_id = aws_vpc_endpoint.tf-endpoint-s3.id
}