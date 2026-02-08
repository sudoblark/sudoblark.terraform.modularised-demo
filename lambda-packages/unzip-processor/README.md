# Unzip Processor Lambda

Python Lambda function that extracts ZIP files uploaded to the landing S3 bucket and uploads the contents to the raw bucket.

## Functionality

- Triggered by S3 `ObjectCreated` events on `.zip` files in the landing bucket
- Extracts all files from the ZIP archive
- Uploads extracted files to the raw bucket preserving folder structure
- Skips directories and hidden files (starting with `.`)
- Handles errors gracefully and continues processing other files if one fails

## Configuration

### Environment Variables

- `RAW_BUCKET`: Short name of the destination bucket (e.g., "raw")
- `LOG_LEVEL`: Logging level (default: "INFO")

### IAM Permissions Required

The Lambda execution role needs:
- `s3:GetObject` on the landing bucket
- `s3:PutObject` on the raw bucket
- CloudWatch Logs permissions for logging

## Development

### Build Deployment Package

```bash
cd lambda-packages/unzip-processor
pip install -r requirements.txt -t .
zip -r ../unzip-processor.zip .
```

### Testing Locally

Create a test event matching S3 notification structure:

```python
{
  "Records": [
    {
      "s3": {
        "bucket": {"name": "aws-sudoblark-development-demos-tf-micro-repo-landing"},
        "object": {"key": "test-data.zip"}
      }
    }
  ]
}
```

## Code Style

- Follows Black formatting (88 character line length)
- Type hints for all function signatures
- Comprehensive docstrings
- PEP 8 naming conventions
