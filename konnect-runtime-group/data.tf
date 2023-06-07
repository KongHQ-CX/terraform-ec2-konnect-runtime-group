data "template_file" "kong_init" {
  template = file("${path.module}/kong-bootstrap.sh.tpl")
  vars = {
    install_kong_from_s3_path = var.install_kong_from_s3_path != null ? var.install_kong_from_s3_path : "",
    vpc_cidr = data.aws_vpc.selected.cidr_block,
    kong_version = var.kong_version,
    runtime_group_name = var.runtime_group_name,
  }
}

data "aws_vpc" "selected" {
  id = var.vpc_id
}

data "aws_caller_identity" "current" {}

# Uses public service to get YOUR IP address - replace with stub if you don't want this
data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

data "aws_default_tags" "tags" {}
