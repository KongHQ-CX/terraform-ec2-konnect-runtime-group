# Create a basic ALB 
resource "aws_alb" "kong_alb" {
  name = "kong-rg-${var.runtime_group_name}"

  subnets = var.subnet_ids
  security_groups = [ aws_security_group.kong_alb.id ]
  internal = var.internal_load_balancer
}

# Create target groups with one health check per group
resource "aws_alb_target_group" "kong_asg_group" {
  name     = "kong-rg-${var.runtime_group_name}"
  port     = 8443
  protocol = "HTTPS"
  vpc_id   = var.vpc_id

  lifecycle { create_before_destroy=true }

  health_check {
    path = "/status"
    port = 8100
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 2
    interval = 5
    matcher = "200"
  }
}

# Create the HTTPS Listener 
resource "aws_alb_listener" "kong_default_https" {
  load_balancer_arn = aws_alb.kong_alb.arn
  
  default_action {
    target_group_arn = aws_alb_target_group.kong_asg_group.arn
    type = "forward"
  }

  port           = 443
  protocol       = "HTTPS"
  certificate_arn = var.acm_certificate_arn
}
