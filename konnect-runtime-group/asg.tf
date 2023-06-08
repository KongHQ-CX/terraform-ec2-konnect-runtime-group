resource "aws_launch_template" "kong_alt" {
  name = "kong-rg-${var.runtime_group_name}"

  ebs_optimized = false # not required for Konnect - disk is rarely used for API proxy traffic

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_profile.name
  }

  image_id = var.ami

  instance_initiated_shutdown_behavior = "terminate"

  # instance_market_options {
  #   market_type = "spot"
  # }

  instance_type = var.instance_tier

  key_name = aws_key_pair.ssh_public_key.key_name

  network_interfaces {
    associate_public_ip_address = var.assign_instance_public_ip
    security_groups = [ aws_security_group.kong_instances.id ]
    delete_on_termination = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = data.aws_default_tags.tags.tags
  }

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = var.root_volume_size
    }
  }

  user_data = base64encode(data.template_file.kong_init.rendered)
}

resource "aws_key_pair" "ssh_public_key" {
  key_name   = "${var.runtime_group_name}-public-key"
  public_key = var.ssh_public_key
}

resource "aws_autoscaling_group" "kong" {
  name                      = "kong-rg-${var.runtime_group_name}"
  max_size                  = var.autoscaling_max_replicas
  min_size                  = var.autoscaling_min_replicas
  desired_capacity          = 1
  force_delete              = true

  launch_template {
    id      = aws_launch_template.kong_alt.id
    version = "$Latest"
  }

  enabled_metrics = [
    "GroupDesiredCapacity",
    "GroupInServiceInstances",
    "GroupMaxSize",
    "GroupMinSize",
    "GroupPendingInstances",
    "GroupStandbyInstances",
    "GroupTerminatingInstances",
    "GroupTotalInstances",
  ]

  vpc_zone_identifier = var.subnet_ids

  health_check_type    = "ELB"
  health_check_grace_period = 300
  target_group_arns = [ aws_alb_target_group.kong_asg_group.arn ]

  timeouts {
    delete = "10m"
  }
}

resource "aws_autoscaling_policy" "kong_autoscaling_policy" {
  name                   = "kong-asp-${var.runtime_group_name}"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 60
  autoscaling_group_name = aws_autoscaling_group.kong.name
}

resource "aws_cloudwatch_metric_alarm" "kong_autoscaling_metric" {
  alarm_name          = "kong-asp-${var.runtime_group_name}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 60
  statistic           = "Average"
  threshold           = 80

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.kong.name
  }

  alarm_description = "Kong runtime group ${var.runtime_group_name} exceeded CPU limits for 120 seconds, causing an autoscaling event."
  alarm_actions     = [aws_autoscaling_policy.kong_autoscaling_policy.arn]
}
