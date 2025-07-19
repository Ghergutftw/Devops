# Data source to get your current public IP
data "http" "my_ip" {
  url = "https://ipv4.icanhazip.com"
}

resource "aws_security_group" "security_group_tf" {
  name        = "security_group_tf"
  description = "security_group_tf"

  tags = {
    Name = "security_group_tf"
  }
}

# Inbound rule - SSH from your current IP
resource "aws_vpc_security_group_ingress_rule" "ssh_from_my_ip" {
  security_group_id = aws_security_group.security_group_tf.id
  #   cidr_ipv4         = "${chomp(data.http.my_ip.response_body)}/32"
  cidr_ipv4   = "0.0.0.0/0" # For testing purposes, allow SSH from anywhere
  from_port   = 22
  ip_protocol = "tcp"
  to_port     = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  security_group_id = aws_security_group.security_group_tf.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.security_group_tf.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.security_group_tf.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1" # semantically equivalent to all ports
}