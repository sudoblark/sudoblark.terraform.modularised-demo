"""
Lambda function to convert CSV files from S3 raw bucket to Parquet format.

This function is triggered by S3 ObjectCreated events on the raw bucket
and converts CSV files to Parquet format with date-based partitioning.
"""

import io
import logging
import os
import re
from datetime import datetime
from typing import Any, Dict, List

import boto3
import pandas as pd
from aws_lambda_powertools.utilities.data_classes import S3Event, event_source
from botocore.exceptions import ClientError

# Configure logging
LOG_LEVEL: str = os.environ.get("LOG_LEVEL", "INFO")
logger = logging.getLogger()
logger.setLevel(LOG_LEVEL)

# Initialize S3 client
s3_client = boto3.client("s3")


def get_config() -> Dict[str, str]:
    """
    Load and validate configuration from environment variables.

    Returns:
        Dictionary containing validated configuration

    Raises:
        ValueError: If required environment variables are missing or invalid
    """
    processed_bucket: str = os.environ.get("PROCESSED_BUCKET", "")
    if not processed_bucket:
        raise ValueError("PROCESSED_BUCKET environment variable is required")

    log_level: str = os.environ.get("LOG_LEVEL", "INFO").upper()
    allowed_levels: List[str] = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
    if log_level not in allowed_levels:
        raise ValueError(f"LOG_LEVEL must be one of {allowed_levels}")

    return {"processed_bucket": processed_bucket, "log_level": log_level}


@event_source(data_class=S3Event)
def handler(event: S3Event, context: Any) -> Dict[str, Any]:
    """
    Lambda handler to process S3 events and convert CSV to Parquet.

    Args:
        event: S3 event data class from Lambda Powertools
        context: Lambda context object

    Returns:
        Response dictionary with:
        - statusCode: HTTP status code (200 or 207)
        - processed_count: Number of files successfully processed
        - failed_count: Number of failures
        - processed_files: List of successfully processed file keys
        - failed_files: List of failed files with error details

    Raises:
        ValueError: If configuration is invalid
        Exception: If processing fails critically
    """
    logger.info(f"Received S3 event with {len(event.records)} record(s)")

    try:
        # Load and validate configuration
        config: Dict[str, str] = get_config()

        processed_files: List[str] = []
        failed_files: List[Dict[str, str]] = []

        # Process each record in the S3 event
        for record in event.records:
            try:
                bucket_name: str = record.s3.bucket.name
                object_key: str = record.s3.object.key

                # Validate S3 key for path traversal
                if ".." in object_key:
                    raise ValueError(f"Invalid S3 key (path traversal): {object_key}")

                logger.info(f"Processing CSV file: s3://{bucket_name}/{object_key}")

                # Convert CSV to Parquet
                parquet_key: str = convert_csv_to_parquet(
                    bucket_name, object_key, config["processed_bucket"]
                )
                processed_files.append(parquet_key)

            except Exception as e:
                logger.error(f"Failed to process record: {str(e)}", exc_info=True)
                failed_files.append({"key": record.s3.object.key, "error": str(e)})

        # Prepare response
        response: Dict[str, Any] = {
            "statusCode": 200 if not failed_files else 207,
            "processed_count": len(processed_files),
            "failed_count": len(failed_files),
            "processed_files": processed_files,
            "failed_files": failed_files,
        }

        logger.info(f"Processing complete: {response}")
        return response

    except Exception as e:
        logger.error(f"Handler execution failed: {str(e)}", exc_info=True)
        raise


def convert_csv_to_parquet(
    source_bucket: str, csv_key: str, processed_bucket_name: str
) -> str:
    """
    Download CSV file from S3, convert to Parquet, and upload with date partitioning.

    Args:
        source_bucket: Source S3 bucket containing the CSV file
        csv_key: S3 key of the CSV file
        processed_bucket_name: Short name of destination bucket

    Returns:
        S3 key of the uploaded Parquet file

    Raises:
        ValueError: If inputs are empty, bucket name format is invalid, or date parsing fails
        ClientError: If S3 operations fail
        pd.errors.ParserError: If CSV parsing fails
    """
    # Validate inputs
    if not source_bucket or not csv_key or not processed_bucket_name:
        raise ValueError(
            "source_bucket, csv_key, and processed_bucket_name must not be empty"
        )

    # Resolve full bucket name (add prefix if needed)
    bucket_parts: List[str] = source_bucket.split("-")
    if len(bucket_parts) < 4:
        raise ValueError(f"Invalid source bucket name format: {source_bucket}")

    account: str = bucket_parts[0]
    project: str = bucket_parts[1]
    application: str = "-".join(bucket_parts[2:-1])
    processed_bucket: str = (
        f"{account}-{project}-{application}-{processed_bucket_name}"
    )

    logger.info(f"Target processed bucket: {processed_bucket}")

    try:
        # Download CSV file from S3
        logger.info(f"Downloading CSV file: s3://{source_bucket}/{csv_key}")
        csv_obj: Dict[str, Any] = s3_client.get_object(Bucket=source_bucket, Key=csv_key)
        csv_content: bytes = csv_obj["Body"].read()

        # Parse CSV to DataFrame
        df: pd.DataFrame = pd.read_csv(io.BytesIO(csv_content))
        logger.info(f"Parsed CSV with {len(df)} rows and {len(df.columns)} columns")

        # Extract date from filename (YYYYmmdd.csv format)
        date_str: str = extract_date_from_filename(csv_key)
        logger.info(f"Extracted date from filename: {date_str}")

        # Convert DataFrame to Parquet
        parquet_buffer: io.BytesIO = convert_dataframe_to_parquet(df)

        # Create partitioned key: year=YYYY/month=MM/day=DD/filename.parquet
        parquet_key: str = create_partitioned_key(csv_key, date_str)
        logger.info(f"Uploading Parquet: s3://{processed_bucket}/{parquet_key}")

        # Upload Parquet file to S3
        s3_client.put_object(
            Bucket=processed_bucket,
            Key=parquet_key,
            Body=parquet_buffer.getvalue(),
            ContentType="application/octet-stream",
        )

        logger.info(f"Successfully converted and uploaded: {parquet_key}")
        return parquet_key

    except ClientError as e:
        logger.error(f"S3 operation failed: {str(e)}", exc_info=True)
        raise
    except pd.errors.ParserError as e:
        logger.error(f"Failed to parse CSV file {csv_key}: {str(e)}", exc_info=True)
        raise


def extract_date_from_filename(filename: str) -> str:
    """
    Extract date from filename in YYYYmmdd format.

    Args:
        filename: File name or path (e.g., "20260101.csv" or "path/20260101.csv")

    Returns:
        Date string in YYYYMMDD format

    Raises:
        ValueError: If filename doesn't contain valid date in YYYYmmdd format
    """
    # Extract basename from path
    basename: str = filename.split("/")[-1]

    # Match YYYYmmdd pattern
    date_pattern: str = r"(\d{8})"
    match = re.search(date_pattern, basename)

    if not match:
        raise ValueError(f"Filename {filename} does not contain date in YYYYmmdd format")

    date_str: str = match.group(1)

    # Validate date format
    try:
        datetime.strptime(date_str, "%Y%m%d")
    except ValueError as e:
        raise ValueError(f"Invalid date format in filename {filename}: {str(e)}")

    return date_str


def convert_dataframe_to_parquet(df: pd.DataFrame) -> io.BytesIO:
    """
    Convert pandas DataFrame to Parquet format in memory.

    Args:
        df: Pandas DataFrame to convert

    Returns:
        BytesIO buffer containing Parquet data

    Raises:
        ValueError: If DataFrame is empty
    """
    if df.empty:
        raise ValueError("DataFrame is empty, cannot convert to Parquet")

    buffer: io.BytesIO = io.BytesIO()
    df.to_parquet(buffer, engine="pyarrow", index=False)
    buffer.seek(0)

    return buffer


def create_partitioned_key(csv_key: str, date_str: str) -> str:
    """
    Create S3 key with date-based partitioning.

    Args:
        csv_key: Original CSV file key
        date_str: Date string in YYYYMMDD format

    Returns:
        Partitioned key in format: year=YYYY/month=MM/day=DD/filename.parquet

    Raises:
        ValueError: If date_str is invalid
    """
    # Parse date
    date_obj: datetime = datetime.strptime(date_str, "%Y%m%d")

    year: str = date_obj.strftime("%Y")
    month: str = date_obj.strftime("%m")
    day: str = date_obj.strftime("%d")

    # Extract filename without path and change extension
    basename: str = csv_key.split("/")[-1]
    parquet_filename: str = basename.replace(".csv", ".parquet")

    # Create partitioned key
    partitioned_key: str = f"year={year}/month={month}/day={day}/{parquet_filename}"

    return partitioned_key
