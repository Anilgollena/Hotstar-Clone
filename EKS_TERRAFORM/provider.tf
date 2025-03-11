terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Use latest in 5.x series
    }
  }
}

provider "aws" {
  region = "us-east-1"  # Change region as needed
}
