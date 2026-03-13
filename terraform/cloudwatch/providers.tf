terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 5.100.0"
    }
  }
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "observability-stack"
      ManagedBy   = "Terraform"
      Environment = var.environment
      Repository  = "https://github.com/justin-henson/observability-stack"
    }
  }
}
