terraform {
    required_version = ">=0.12.13"
}

provider "aws" {
    region  = "us-east-1"
    version = "~> 3.24.1"
}

module "bootstrap" {
    source                      = "./modules/bootstrap"
    name_of_s3_bucket           = "pssgoifo-clickcount-state"
    dynamo_db_table_name        = "aws-locks"
}
