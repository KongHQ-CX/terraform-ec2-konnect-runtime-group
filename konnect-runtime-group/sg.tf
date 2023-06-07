# ALB security group
resource "aws_security_group" "kong_alb" {
  name        = "allow_kong_proxy_traffic_${var.runtime_group_name}"
  description = "Allow Kong Runtime Group Traffic for ${var.runtime_group_name}"
  vpc_id      = var.vpc_id

  ingress {
    description      = "HTTPS (proxy) from My Computer"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = concat(["${chomp(data.http.myip.body)}/32"], var.inbound_ip_cidrs_allowed)
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Instance security group
resource "aws_security_group" "kong_instances" {
  name        = "allow_alb_traffic_${var.runtime_group_name}"
  description = "Allow Kong ALB Traffic for ${var.runtime_group_name}"
  vpc_id      = var.vpc_id

  ingress {
    description      = "SSH from My Computer"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["${chomp(data.http.myip.body)}/32"]
  }

  ingress {
    description      = "HTTPS (proxy) from ALB"
    from_port        = 8443
    to_port          = 8443
    protocol         = "tcp"
    security_groups  = [aws_security_group.kong_alb.id]
  }

  ingress {
    description      = "Status Check from ALB"
    from_port        = 8100
    to_port          = 8100
    protocol         = "tcp"
    security_groups  = [aws_security_group.kong_alb.id]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  
  lifecycle {
    create_before_destroy = true
  }
}
