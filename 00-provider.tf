provider "aws" {
  shared_credentials_files = ["~/.aws/credentials"]
  profile                  = var.profile
  region                   = var.aws_region
  allowed_account_ids      = [var.allowed_account_ids]
}
