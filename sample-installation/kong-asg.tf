module "kong_asg" {
  source = "../konnect-runtime-group"

  # Kong Konnect settings
  kong_version = "3.3.0.0"
  runtime_group_name = "jack-kong"

  ami = "ami-05264014b9e517c33"

  ssh_public_key = "ssh-ed25519 AAAAC........ user@domain.local"

  # vpc information for deployment
  availability_zones = ["eu-west-1a", "eu-west-1b"]
  vpc_id = "vpc-0acf55493d6601b0f"
  subnet_ids = ["subnet-0123456789abcdef01", "subnet-1234567890abfed1"]

  # load balancer setup
  hosted_zone_id = "Z05ABC519MSF5I7H9I1T1"
  hosted_zone_domain = "aws.jack.local"
  acm_certificate_arn = "arn:aws:acm:eu-west-1:012345678901:certificate/abcedf12-1234-abcd-1234-abced1234abc"

  do_acm_certificate_request = false
}
