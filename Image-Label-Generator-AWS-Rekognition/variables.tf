variable "region" {
  description = "AWS region"
  type = string
  default = "eu-central-1"
}

variable "bucket_name" {
  description = "S3 bucket name"
  type = string
  default = "image-label-bucket"
}

variable "profile_default" {
  description = "AWS CLI profile to use"
  default = "AdministratorAccess-985539787837"
  type        = string
}