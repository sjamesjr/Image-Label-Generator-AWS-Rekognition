# Image Label Generator using AWS Rekognition

This project provisions a cloud-based image labeling system using AWS services, Terraform for infrastructure-as-code, and Python for image analysis and visualization. Images are uploaded to an Amazon S3 bucket, processed by Amazon Rekognition to detect labels and bounding boxes, and displayed locally with visual overlays.

## Features

* Fully automated AWS provisioning using Terraform
* Secure S3 bucket for image storage
* IAM configuration to allow controlled programmatic access
* Python script that retrieves images from S3
* Rekognition-based object and scene detection
* Bounding-box visualization and label confidence output
* Environment-variable driven configuration (no hard-coded bucket names)

## Architecture Overview

```
Local Machine → AWS CLI → S3 Bucket → Rekognition → Python Script → Visual Output
```

## Components

| Component            | Purpose                                                         |
| -------------------- | --------------------------------------------------------------- |
| Terraform            | Creates S3 bucket, IAM user, and policies                       |
| AWS S3               | Stores images to be analyzed                                    |
| AWS IAM              | Manages authentication for CLI + Python script                  |
| Amazon Rekognition   | Detects labels and bounding boxes in images                     |
| Python (boto3 + PIL) | Fetches images, runs Rekognition, and displays annotated images |

## Prerequisites

* Python 3.8+
* AWS CLI installed and configured
* Terraform installed
* `boto3` and `Pillow` Python libraries

## Setup Instructions

### 1. Clone the Repository

```
git clone <your repository URL>
cd Image-Label-Generator-AWS-Rekognition
```

### 2. Initialize Terraform and Deploy Infrastructure

```
cd terraform
terraform init
terraform apply
```

### 3. Export Bucket Name as Environment Variable

```
export S3_BUCKET_NAME=$(terraform output -raw s3_bucket_name)
```

### 4. Upload Images to S3

```
aws s3 cp ./images/<your_image>.jpg s3://$S3_BUCKET_NAME/
```

### 5. Run the Python Script

```
python labeler_popup.py <image_key>
```

Example:

```
python labeler_popup.py dog.jpg
```

## Output Example

The script will:

* Download the image from S3
* Send it to Rekognition for analysis
* Display the detected labels and confidence scores
* Show an annotated image pop-up with bounding boxes drawn

## Potential Use Cases

| Use Case                          | Description                                                          |
| --------------------------------- | -------------------------------------------------------------------- |
| E-commerce product classification | Automatically categorize product photos based on detected attributes |
| Wildlife monitoring and research  | Identify species from trail cam images                               |
| Inventory or warehouse scanning   | Detect objects present in warehouse image feeds                      |
| Educational or training tools     | Teach image recognition workflows and computer vision pipelines      |
| Security camera analysis          | Identify objects or individuals in captured footage                  |

## Security Considerations

* Do not hardcode AWS credentials in code
* Use IAM least privilege policies
* Enable S3 bucket block-public-access and encryption

## Future Enhancements

* Add automatic image labeling export to CSV
* Build Streamlit web UI for browsing images
* Integrate Rekognition Custom Labels model
* Save annotated images back to S3

## License

MIT License
