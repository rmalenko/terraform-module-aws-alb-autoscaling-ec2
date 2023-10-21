# The set of these modules for create ALB, WAF, ASG, EC2, R53, IAM, RDS Secrets, S3, EFS, VPC

## ALB

Rules:

- redirect www to non www
- redirect HTTP to HTTP(S)

## WAF

Rules:

- Managed_Rules_WordPress_Rule_Set
- Managed_Rules_PHP_Rule_Set
- Managed_Rules_SQLi_Rule_Set
- IP_Rate_Based_Rule (`var.ip_rate_limit_reqests_num`)
- Block_country (`var.country_codes_block`)

## ASG

Autoscaling policy:

- UP/DOWN adding 2 instance or remove one
- by CPU UP - (75%), DOWN - (50%)
- ASG 5XX error more 10% and Downscale when less 5%

## EC2

- Placement group
- SSH keys (RSA and DSA)

## Template

- AMI Amazon Linux 2
- Instance type - `local.instance_type`
- Instance type `Spot` - `module.spot-price.spot_price_current_optimal`
- ENS GP3 20Gb
  

## EFS (NFS)

- Encrypted by (`module.iam.aws_kms_key_arn`)

## IAM

- KMS key
- SSM, EFS, RDF policy

## S3

- Bucket for ALB logs

## Secrets

Password and login for RDS will be available as ENV variables inside instances:

- `MYSQL_PASSWD`
- `MYSQL_LOGIN`
- `MYSQL_DBNAME`
- `MYSQL_ADDRESS`
- Password, Login generated automatically and DB name.

## RDS

- Engine `aurora-mysql`, mode `serverless`
- `scaling_configuration` `min = 1`, `max = 2`

## VPC

Two zones (a and b) and private and public subnets.


## Used modules

`git submodule init`

- An easy way to get the best Spot price to control costs. [terraform-aws-ec2-spot-price](https://github.com/fivexl/terraform-aws-ec2-spot-price)
- Creates S3 bucket on AWS with all (or almost all) features provided by Terraform AWS provider. [terraform-aws-s3-bucket](https://github.com/terraform-aws-modules/terraform-aws-s3-bucket)
- EC2 security group within VPC on AWS. [terraform-aws-security-group](https://github.com/terraform-aws-modules/terraform-aws-security-group)
- AWS VPC Terraform module [terraform-aws-vpc](https://github.com/terraform-aws-modules/terraform-aws-vpc)

![Alt text](https://github.com/rmalenko/terraform-module-aws-alb-autoscaling-ec2/blob/main/docs/Amazon_DynamoDB.png)
![Alt text](https://github.com/rmalenko/terraform-module-aws-alb-autoscaling-ec2/blob/main/docs/aws-asg-wp.drawio.png)
