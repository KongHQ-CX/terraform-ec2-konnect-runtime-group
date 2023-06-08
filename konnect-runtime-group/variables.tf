variable "kong_version" {
  description = "Kong Enterprise Gateway version to install."
  type = string
  default = "3.3.0.0"
}

variable "runtime_group_name" {
  description = "Runtime group name to deploy from."
  type = string
}

variable "inbound_ip_cidrs_allowed" {
  description = "List of inbound CIDR blocks that can call this Kong runtime group."
  type = list
  default = []
}

variable "install_kong_from_s3_path" {
  description = "If set, for example: s3://bucket-name/kong-3.3.0.0.deb, then the EC2 instance will try to download Kong from this S3 location instead of the KongHQ distribution website."
  type = string
  default = null
}

variable "do_acm_certificate_request" {
  description = "If true, will perform an ACM certificate request, and insert the validation options into the Route53 record."
  type = bool
  default = false
}

variable "vpc_id" {
  description = "VPC ID to install this Kong deployment in to."
  type = string
}

variable "internal_load_balancer" {
  description = "Set true to produce an internal only load balancer, on the given internal subnets, or set false for public-facing ALB."
  type = bool
  default = false
}

variable "hosted_zone_id" {
  description = "Route53 hosted zone to add ALB records to."
  type = string
}

variable "hosted_zone_domain" {
  description = "Route53 domain, in the format e.g: 'domain.name.local'"
  type = string
  default = "kong.local"
}

variable "acm_certificate_arn" {
  description = "ACM certificate to attach to the ALB."
  type = string
}

variable "use_nlb" {
  description = "Set true to use an NLB instead of ALB. Usually required for mutual-TLS support."
  type = bool
  default = false
}

variable "capacity_reservation_preference" {
  description = "Capacity reservation preference for Kong instances."
  type = string
  default = "open"
}

variable "availability_zones" {
  description = "Array of AZs to run this Kong proxy set in."
  type = list
}

variable "subnet_ids" {
  description = "Array of subnets to scale this Kong deployment across."
  type = list
}

variable "ami" {
  description = "AMI ID to use for launching and running Kong services."
  type = string
  default = "ami-05264014b9e517c33"  # Amazon-published Ubuntu 18.04.6 image
}

variable "instance_tier" {
  description = "Instance tier to use for Kong gateway deployment."
  type = string
  default = "t3.medium"
}

variable "autoscaling_min_replicas" {
  description = "Minimum Kong replicas for this RG."
  type = number
  default = 1
}

variable "autoscaling_max_replicas" {
  description = "Maximum Kong replicas for this RG."
  type = number
  default = 2
}

variable "assign_instance_public_ip" {
  description = "Whether to assign a public IP address to the instances, for SSH and/or console access."
  type = bool
  default = false
}

variable "ssh_public_key" {
  description = "Public Key string to use for SSH access to the Kong instances."
  type = string
  default = null
}

variable "root_volume_size" {
  description = "Size in Gigabytes of the root volume for the Kong Gateway."
  type = number
  default = 40
}
