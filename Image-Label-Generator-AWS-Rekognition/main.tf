terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">=3.5"
    }
  }
}

provider "aws" {
  profile = "AdministratorAccess-985539787837"
  region  = var.region
}

# Generate a random suffix for unique bucket names
resource "random_id" "suffix" {
  byte_length = 4
}

# ✅ Create the S3 bucket (with inline ACL to avoid NoSuchBucket error)
resource "aws_s3_bucket" "images" {
  bucket = "image-label-bucket-${random_id.suffix.hex}"

}


# ✅ Block all public access to the bucket
resource "aws_s3_bucket_public_access_block" "my_bucket_block" {
  bucket = aws_s3_bucket.images.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ✅ Use correct resource type for lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "my_bucket_lifecycle" {
  bucket = aws_s3_bucket.images.id

  rule {
    id     = "expire_old_objects"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

# ✅ IAM policy allowing Rekognition + S3 access
data "aws_iam_policy_document" "rekog_s3_policy" {
  statement {
    sid = "AllowS3GetObject"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
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

# ✅ Create IAM user for CLI
resource "aws_iam_user" "cli_user" {
  name = "image_label_cli_user"
  tags = {
    created_by = "terraform"
  }
}

# ✅ Attach policy to user
resource "aws_iam_user_policy_attachment" "attach_policy" {
  user       = aws_iam_user.cli_user.name
  policy_arn = aws_iam_policy.rekog_s3_policy.arn
}
