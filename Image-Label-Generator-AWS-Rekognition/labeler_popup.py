#!/usr/bin/env python3
"""
labeler_popup.py
- Downloads image from S3
- Calls Rekognition detect_labels
- Draws bounding boxes for instances and shows image in a popup
- Prints labels + confidence
"""

import boto3
from PIL import Image, ImageDraw
import io
import os
import sys
import subprocess

# ----------------------------
# 1. Configuration
# ----------------------------

# S3 bucket: either from environment or Terraform output
bucket_name = os.environ.get("S3_BUCKET_NAME")
if not bucket_name:
    try:
        # Try to get bucket name from Terraform
        result = subprocess.run(
            ["terraform", "output", "-raw", "s3_bucket_name"],
            capture_output=True,
            text=True,
            check=True
        )
        bucket_name = result.stdout.strip()
    except Exception:
        print("❌ ERROR: Could not determine S3 bucket name.")
        print("Set S3_BUCKET_NAME or run Terraform first.")
        sys.exit(1)

# AWS profile to use (environment variable or default)
aws_profile = os.environ.get("AWS_PROFILE", "AdministratorAccess-985539787837")

# Validate image key argument
if len(sys.argv) < 2:
    print("Usage: python labeler_popup.py <image_key>")
    sys.exit(1)

image_key = sys.argv[1]

# ----------------------------
# 2. Create AWS session/clients
# ----------------------------

try:
    session = boto3.Session(profile_name=aws_profile)
    s3 = session.client("s3")
    rekognition = session.client("rekognition")
except Exception as e:
    print(f"❌ ERROR: Could not create AWS session with profile {aws_profile}")
    print(e)
    sys.exit(1)

# ----------------------------
# 3. Retrieve image bytes from S3
# ----------------------------

try:
    obj = s3.get_object(Bucket=bucket_name, Key=image_key)
    image_bytes = obj["Body"].read()
except Exception as e:
    print(f"❌ ERROR: Could not read image '{image_key}' from bucket '{bucket_name}'")
    print(e)
    sys.exit(1)

# ----------------------------
# 4. Call Rekognition detect_labels
# ----------------------------

try:
    response = rekognition.detect_labels(
        Image={"Bytes": image_bytes},
        MaxLabels=10,
        MinConfidence=70
    )
except Exception as e:
    print("❌ ERROR: Rekognition detect_labels failed")
    print(e)
    sys.exit(1)

# ----------------------------
# 5. Draw bounding boxes
# ----------------------------

image = Image.open(io.BytesIO(image_bytes))
img_width, img_height = image.size
draw = ImageDraw.Draw(image)

for label in response.get("Labels", []):
    for instance in label.get("Instances", []):
        box = instance.get("BoundingBox")
        if not box:
            continue

        left = img_width * box["Left"]
        top = img_height * box["Top"]
        width = img_width * box["Width"]
        height = img_height * box["Height"]

        # Draw bounding box
        draw.rectangle([left, top, left + width, top + height], outline="red", width=3)
        draw.text((left, top - 10), label["Name"], fill="red")

# ----------------------------
# 6. Display image and results
# ----------------------------

image.show()

print("\n✅ Analysis Complete!")
print(f"🪣 Bucket: {bucket_name}")
print(f"🖼️ Image: {image_key}\n")

print("Detected Labels:")
for label in response.get("Labels", []):
    print(f"- {label['Name']} ({label['Confidence']:.2f}%)")
