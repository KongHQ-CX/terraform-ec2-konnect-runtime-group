resource "aws_iam_instance_profile" "ec2_profile" {
    name = "kong-${var.runtime_group_name}-profile"
    role = aws_iam_role.kong_iam_role.name
}

resource "aws_iam_role" "kong_iam_role" {
  name = "kong-${var.runtime_group_name}-role"

  # Terraform's "jsonencode" function converts a
  # Terraform expression result to valid JSON syntax.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Sid    = ""
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  inline_policy {
    name   = "read-runtimegroup-information"
    policy = data.aws_iam_policy_document.read_runtimegroup_information.json
  }

  dynamic "inline_policy" {
    for_each = local.s3_path_parsed != null ? [ local.s3_path_parsed ] : []
    content {
      name   = "read-kong-deb-bucket"
    policy = data.aws_iam_policy_document.read_kong_deb_bucket[0].json
    }
  }
}

data "aws_iam_policy_document" "read_runtimegroup_information" {
  statement {
    actions   = [
      "secretsmanager:GetSecretValue",
    ]
    resources = [
      "arn:aws:secretsmanager:*:${data.aws_caller_identity.current.account_id}:secret:konnect/rg/${var.runtime_group_name}-*",
    ]
  }
}

data "aws_iam_policy_document" "read_kong_deb_bucket" {
  count = local.s3_path_parsed != null ? 1 : 0

  statement {
    actions   = [
      "s3:GetObject",
    ]
    resources = [ "arn:aws:s3:::${local.s3_path_parsed["authority"]}${local.s3_path_parsed["path"]}" ]
  }
}

locals {
  s3_path_parsed = var.install_kong_from_s3_path != null ? regex("(?:(?P<scheme>[^:/?#]+):)?(?://(?P<authority>[^/?#]*))?(?P<path>[^?#]*)(?:\\?(?P<query>[^#]*))?(?:#(?P<fragment>.*))?", var.install_kong_from_s3_path) : null
}