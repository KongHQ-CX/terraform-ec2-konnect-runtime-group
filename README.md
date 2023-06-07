# Terraform EC2 Konnect Runtime Group

Terraform module to install a (set of) Konnect data-plane proxies for a specific runtime group, onto EC2.

## Setup

❗ **BEFORE RUNNING THIS MODULE, YOU NEED TO CONFIGURE AWS SECRETS MANAGER WITH THE RUNTIME GROUP INFORMATION**

Follow these steps, creating the appropriate AWS Secret for the target runtime group:

### 1. Get Runtime Group Information

a) Log in to Konnect, select your runtime group (or create one) and then select **Runtime Instaces**, then **+ New Runtime Instance**

![Add runtime instances](./.assets/1-add-instances.png "Add runtime instances")

b) Now select **Linux**, then press **Generate certificate**

![Generate certificate](./.assets/2-generate-certificate.png "Generate certificate")

c) Save these files somewhere locally.

d) Scroll down to the **Configuration Parameters** and copy/save the two values circled here

![Copy values](./.assets/3-copy-values.png "Copy values")

> So you now should have four things saved:
> - certificate
> - private key
> - cluster server name
> - telemetry server name

### 2. Create AWS Secret

a) Flatten the certificate file by replacing new lines with "\n", or use a shell:

```sh
$ sed '$!s/$/\\n/' cluster-cert.crt | tr -d '\n' > cluster-cert-flattened.crt
```

b) Repeat this for the private key file

c) Create this JSON object, like this **example** (replace the values with those recorded earlier):

```json
{
    "cluster_hostname": "b856eb297b.eu.cp0.konghq.com",
    "telemetry_hostname": "b856eb297b.eu.tp0.konghq.com",
    "cert": "-----BEGIN CERTIFICATE-----\nMIIDhDCCAm6gAwIB........zvA==\n-----END CERTIFICATE-----",
    "key": "-----BEGIN PRIVATE KEY-----\nMIIEvwIBADANBgkq.........l2L4CL2Q==\n-----END PRIVATE KEY-----"
}
```

d) Create an AWS secret with the name exactly in this format: `konnect/rg/runtime_group_name_here`

Like this example:

![Create secret](./.assets/4-create-secret.png "Create secret")

e) When creating select **Other type of secret** and paste the above JSON you created, using the **Plaintext** tab:

![Create secret](./.assets/5-create-secret.png "Create secret")

f) Now we can install the Terraform module.

## Installation

The easiest reference, is to follow the [example parent module setup in this same repository](./sample-installation/).

The most important variables to set in the module are:

```properties
runtime_group_name = "jack-kong"  # MOST IMPORTANT - used for matching Secrets Manager values and other tracking
ami = "ami-05264014b9e517c33"     # set to your managed / hardened AMI

ssh_public_key = "single line public key string for ssh access, not always required"

# vpc information for deployment
availability_zones = ["eu-west-1a", "eu-west-1b"]  # required for scaling and load balancing
vpc_id = "vpc-0acf55493d6601b0f"
subnet_ids = ["subnet-0123456789abcdef01", "subnet-1234567890abfed1"]  # must be in the same AZs as specified above

# load balancer setup
hosted_zone_id = "Z05ABC519MSF5I7H9I1T1"  # we will create a dns record automatically in this zone
hosted_zone_domain = "aws.jack.local"     # url will end up being: "https://$rg_name.$hosted_zone_domain"
acm_certificate_arn = "arn:aws:acm:eu-west-1:012345678901:certificate/abcedf12-1234-abcd-1234-abced1234abc" # required to set the SSL listener on the ALB  # not required if 'do_acm_certificate_request' is true - see below

# optional - if you have an ACM CA set up, you can automatically request and trust the certificate with this option
do_acm_certificate_request = true
```

# Terraform Reference

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_http"></a> [http](#provider\_http) | n/a |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.cert](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_alb.kong_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/alb) | resource |
| [aws_alb_listener.kong_default_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/alb_listener) | resource |
| [aws_alb_target_group.kong_asg_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/alb_target_group) | resource |
| [aws_autoscaling_group.kong](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_autoscaling_policy.kong_autoscaling_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_policy) | resource |
| [aws_iam_instance_profile.ec2_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.kong_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_key_pair.ssh_public_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_launch_template.kong_alt](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_route53_record.cname_route53_record_dynamic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.cname_route53_record_static](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_security_group.kong_alb](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group.kong_instances](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.read_kong_deb_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.read_runtimegroup_information](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |
| [http_http.myip](https://registry.terraform.io/providers/hashicorp/http/latest/docs/data-sources/http) | data source |
| [template_file.kong_init](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | ACM certificate to attach to the ALB. | `string` | n/a | yes |
| <a name="input_ami"></a> [ami](#input\_ami) | AMI ID to use for launching and running Kong services. | `string` | `"ami-05264014b9e517c33"` | no |
| <a name="input_assign_instance_public_ip"></a> [assign\_instance\_public\_ip](#input\_assign\_instance\_public\_ip) | Whether to assign a public IP address to the instances, for SSH and/or console access. | `bool` | `false` | no |
| <a name="input_autoscaling_max_replicas"></a> [autoscaling\_max\_replicas](#input\_autoscaling\_max\_replicas) | Maximum Kong replicas for this RG. | `number` | `2` | no |
| <a name="input_autoscaling_min_replicas"></a> [autoscaling\_min\_replicas](#input\_autoscaling\_min\_replicas) | Minimum Kong replicas for this RG. | `number` | `1` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | Array of AZs to run this Kong proxy set in. | `list` | n/a | yes |
| <a name="input_capacity_reservation_preference"></a> [capacity\_reservation\_preference](#input\_capacity\_reservation\_preference) | Capacity reservation preference for Kong instances. | `string` | `"open"` | no |
| <a name="input_do_acm_certificate_request"></a> [do\_acm\_certificate\_request](#input\_do\_acm\_certificate\_request) | If true, will perform an ACM certificate request, and insert the validation options into the Route53 record. | `bool` | `false` | no |
| <a name="input_hosted_zone_domain"></a> [hosted\_zone\_domain](#input\_hosted\_zone\_domain) | Route53 domain, in the format e.g: 'domain.name.local' | `string` | `"kong.local"` | no |
| <a name="input_hosted_zone_id"></a> [hosted\_zone\_id](#input\_hosted\_zone\_id) | Route53 hosted zone to add ALB records to. | `string` | n/a | yes |
| <a name="input_inbound_ip_cidrs_allowed"></a> [inbound\_ip\_cidrs\_allowed](#input\_inbound\_ip\_cidrs\_allowed) | List of inbound CIDR blocks that can call this Kong runtime group. | `list` | `[]` | no |
| <a name="input_install_kong_from_s3_path"></a> [install\_kong\_from\_s3\_path](#input\_install\_kong\_from\_s3\_path) | If set, for example: s3://bucket-name/kong-3.3.0.0.deb, then the EC2 instance will try to download Kong from this S3 location instead of the KongHQ distribution website. | `string` | `null` | no |
| <a name="input_instance_tier"></a> [instance\_tier](#input\_instance\_tier) | Instance tier to use for Kong gateway deployment. | `string` | `"t3.medium"` | no |
| <a name="input_kong_version"></a> [kong\_version](#input\_kong\_version) | Kong Enterprise Gateway version to install. | `string` | `"3.3.0.0"` | no |
| <a name="input_root_volume_size"></a> [root\_volume\_size](#input\_root\_volume\_size) | Size in Gigabytes of the root volume for the Kong Gateway. | `number` | `40` | no |
| <a name="input_runtime_group_name"></a> [runtime\_group\_name](#input\_runtime\_group\_name) | Runtime group name to deploy from. | `string` | n/a | yes |
| <a name="input_ssh_public_key"></a> [ssh\_public\_key](#input\_ssh\_public\_key) | Public Key string to use for SSH access to the Kong instances. | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | Array of subnets to scale this Kong deployment across. | `list` | n/a | yes |
| <a name="input_use_nlb"></a> [use\_nlb](#input\_use\_nlb) | Set true to use an NLB instead of ALB. Usually required for mutual-TLS support. | `bool` | `false` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID to install this Kong deployment in to. | `string` | n/a | yes |

## Outputs

No outputs.