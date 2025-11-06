terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">=5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_s3_bucket" "images"{
  bucket = var.bucket_name
}

#Block public access by default
block_public_acls = true
block_public_policy = true
restrict_public_buckets = true

lifecyle_rule {
  enabled = true
  expiration {
    days =365
  }

  id = "expire-one-year"
}

# IAM policy allowing S3 GetObject and Rekognition DetectLabels
data "aws_iam_policy_document" "rekog_s3_policy" {
  statement {
    sid = "AllowS3GetObject"
    actions = [
    "s3:GetObject"
    "s3:ListBucket"]
    resources = [
    aws_s3_bucket.images.arn,
    "${aws_s3_bucket.images.arn}/*"
    ]
  }
  statement {
    sid = "AllowRekognitionDetect"
    actions = [
    "rekognition:DetectLabels",
    "rekognition:DetectModerationLabels",
    "rekognition:DetectFaces",
    "rekognition:DetectText"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "rekog_s3_policy" {
  name = "ImageLabeler_Rekognition_S3_Policy"
  policy = data.aws_iam_policy_document.rekog_s3_policy.json
}

# Create IAM user for CLI
resource "aws_iam_user" "cli_user" {
  name = "image_label_cli_user"
  tags = {
    created_by = "terraform"
  }
}

resource "aws_iam_policy_attachment" "attach_policy" {
  user      = aws_iam_user.cli_user.name
  policy_arn = aws_iam_policy.rekog_s3_policy.arn
  name = ""
}