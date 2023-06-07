variable "aws_region" {
  description = "AWS region to install this runtime group in to."
  type = string
}


variable "global_tags" {
  description = "Tags to apply to all objects."
  type = map
  default = {}
}
