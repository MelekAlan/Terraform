terraform {
  required_providers {
    github = {
      source  = "integrations/github"
      version = "4.23.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = "4.9.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

provider "github" {
  token = "xxxxxxxxxxxxxxxxxxxxx"
}