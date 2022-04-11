terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.9.0"
    }
  }
}

provider "aws" {
  # Configuration options
  region = "us-east-1"
}

resource "aws_s3_bucket" "website_bucket" {
  bucket = "test-deneme-melek"
  acl = "public-read"
  policy = file("./policy.json")
  website {
    index_document = "index.html"
    error_document = "index.html"
  }
}

resource "aws_s3_bucket_object" "index" {
  bucket       = aws_s3_bucket.website_bucket.bucket
  key          = "index.html"
  source       = "./index.html"
  content_type = "text/html"
  etag         = md5(file("./index.html"))
  acl          = "public-read"
}
