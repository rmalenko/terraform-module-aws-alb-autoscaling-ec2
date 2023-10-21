// The referenced S3 bucket must have been previously created.

terraform {
  backend "s3" {
    bucket         = "asg-wp-terraform-state-us-east-1"
    dynamodb_table = "asg-wp-tf-locks-us-east-1"
    encrypt        = true
    key            = "asg-wp/terraform.tfstate"
    profile        = "rmalenko"
    region         = "us-east-1"
  }
}
