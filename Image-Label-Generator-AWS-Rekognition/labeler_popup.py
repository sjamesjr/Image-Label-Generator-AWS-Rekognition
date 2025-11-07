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

# ----------------------------
# 1. Read bucket + image from environment or command line
# ----------------------------

# Retrieve bucket name from environment variable

bucket_name = os.environ["S3_BUCKET_NAME"]

if not bucket_name:
    print("❌ ERROR: Environment variable S3_BUCKET_NAME is not set.")
    print("Run: export S3_BUCKET_NAME=$(terraform output -raw s3_bucket_name)")
    sys.exit(1)

# Allow user to select which image to analyze

if len(sys.argv) < 2:
    print("Usage: python labeler_popup.py <image_key>")
    sys.exit(1)

image_key = sys.argv[1]

# ----------------------------
# 2. Create AWS Clients
# ----------------------------

s3 = boto3.client("s3")
rekognition = boto3.client("rekognition")


# ----------------------------
# 3. Retrieve image bytes from S3
# ----------------------------

try:
    obj = s3.get_object(Bucket=bucket_name, Key=image_key)
    image_bytes = obj["Body"].read()
except Exception as e:
    print(f"❌ ERROR: Could not read image {image_key} from bucket {bucket_name}")
    print(e)
    sys.exit(1)

# ----------------------------
# 4. Send Image to Rekognition
# ----------------------------

response = rekognition.detect_labels(
    Image={"Bytes": image_bytes},
    MaxLabels=10,
    MinConfidence=70
)

# ----------------------------
# 5. Draw bounding boxes on the image
# ----------------------------

image = Image.open(io.BytesIO(image_bytes))
img_width, img_height = image.size
draw = ImageDraw.Draw(image)

for label in response["Labels"]:
    for instance in label.get("Instances", []):
        if "BoundingBox" not in instance:
            continue

        box = instance["BoundingBox"]

        left = img_width * box["Left"]
        top = img_height * box["Top"]
        width = img_width * box["Width"]
        height = img_height * box["Height"]

        # Draw bounding box
        draw.rectangle([left,top,left + width, top + height], outline="red", width=3)

        # Label text
        draw.text((left, top - 10), label["Name"], fill="red")


# ----------------------------
# 6. Display the Image
# ----------------------------

image.show()

print("\n✅ Analysis Complete!")
print(f"🪣Bucket: {bucket_name}")
print(f"🖼️ Image: {image_key}\n")

print("Detected Labels")
for label in response["Labels"]:
    print(f"- {label["Name"]} ({label["Confidence"]: .2f}%)")