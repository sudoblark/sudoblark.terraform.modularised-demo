# Parquet Converter Lambda

Python Lambda function that converts CSV files from the raw S3 bucket to Parquet format with date-based partitioning in the processed bucket.

## Functionality

- Triggered by S3 `ObjectCreated` events on `.csv` files in the raw bucket
- Parses CSV files using pandas
- Converts to Parquet format using PyArrow
- Extracts date from filename (YYYYmmdd.csv format)
- Creates date-partitioned directory structure: `year=YYYY/month=MM/day=DD/filename.parquet`
- Uploads Parquet files to processed bucket

## Configuration

### Environment Variables

- `PROCESSED_BUCKET`: Short name of the destination bucket (e.g., "processed")
- `LOG_LEVEL`: Logging level (default: "INFO")

### IAM Permissions Required

The Lambda execution role needs:
- `s3:GetObject` on the raw bucket
- `s3:PutObject` on the processed bucket
- CloudWatch Logs permissions for logging

## Date Partitioning

Files are organized using Hive-style partitioning:

```
processed/
├── year=2026/
│   ├── month=01/
│   │   ├── day=01/
│   │   │   └── 20260101.parquet
│   │   ├── day=02/
│   │   │   └── 20260102.parquet
│   │   └── day=03/
│   │       └── 20260103.parquet
```

This structure enables efficient querying with AWS Athena or other analytics tools.

## Development

### Build Deployment Package

```bash
cd lambda-packages/parquet-converter
pip install -r requirements.txt -t .
zip -r ../parquet-converter.zip .
```

### Testing Locally

Create a test event matching S3 notification structure:

```python
{
  "Records": [
    {
      "s3": {
        "bucket": {"name": "aws-sudoblark-development-demos-tf-micro-repo-raw"},
        "object": {"key": "20260101.csv"}
      }
    }
  ]
}
```

## Code Style

- Follows Black formatting (88 character line length)
- Type hints for all function signatures and variables
- Comprehensive docstrings
- PEP 8 naming conventions
- AWS Lambda Powertools for event handling
- Separated business logic for testability

## Dependencies

- **boto3**: AWS SDK for Python
- **aws-lambda-powertools**: Structured event parsing
- **pandas**: CSV parsing and data manipulation
- **pyarrow**: Parquet file format support
