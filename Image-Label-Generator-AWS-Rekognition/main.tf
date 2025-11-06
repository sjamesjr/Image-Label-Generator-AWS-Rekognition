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

resource "aws_s3_bucket_public_access_block" "my_bucket_block" {
  bucket = aws_s3_bucket.images.id

  #Block public access by default
  block_public_acls = true
  block_public_policy = true
  restrict_public_buckets = true
}

resource "aws_s3control_bucket_lifecycle_configuration" "my_bucket_lifecycle" {
  bucket = aws_s3_bucket.images.id

  rule {
    id     = "expired_old_objects"
    status = "Enabled"

    expiration {
      days = 30
    }
  }

# IAM policy allowing S3 GetObject and Rekognition DetectLabels
}
data "aws_iam_policy_document" "rekog_s3_policy" {
  statement {
    sid = "AllowS3GetObject"
    actions = [
    "s3:GetObject",
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
  name   = "ImageLabeler_Rekognition_S3_Policy"
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
  name = "attach_rekog_s3_policy"
  users      = [aws_iam_user.cli_user.name]
  policy_arn = aws_iam_policy.rekog_s3_policy.arn

}