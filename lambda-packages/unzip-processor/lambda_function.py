"""
Lambda function to extract ZIP files from S3 landing bucket to raw bucket.

This function is triggered by S3 ObjectCreated events on the landing bucket
and extracts all files from uploaded ZIP archives to the raw bucket.
"""

import io
import logging
import os
import zipfile
from typing import Any, Dict, List, Tuple

import boto3
from aws_lambda_powertools.utilities.data_classes import S3Event, event_source
from botocore.exceptions import ClientError

# Configure logging
LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO")
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
    raw_bucket: str = os.environ.get("RAW_BUCKET", "")
    if not raw_bucket:
        raise ValueError("RAW_BUCKET environment variable is required")

    log_level: str = os.environ.get("LOG_LEVEL", "INFO").upper()
    allowed_levels: List[str] = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
    if log_level not in allowed_levels:
        raise ValueError(f"LOG_LEVEL must be one of {allowed_levels}")

    return {"raw_bucket": raw_bucket, "log_level": log_level}


@event_source(data_class=S3Event)
def handler(event: S3Event, context: Any) -> Dict[str, Any]:
    """
    Lambda handler to process S3 events and extract ZIP files.

    Args:
        event: S3 event data class from Lambda Powertools
        context: Lambda context object

    Returns:
        Dictionary containing status and processing results with keys:
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

                logger.info(f"Processing ZIP file: s3://{bucket_name}/{object_key}")

                # Extract files from ZIP
                extracted: List[str] = extract_zip_to_raw_bucket(
                    bucket_name, object_key, config["raw_bucket"]
                )
                processed_files.extend(extracted)

            except Exception as e:
                logger.error(f"Failed to process record: {str(e)}", exc_info=True)
                failed_files.append({"key": record.s3.object.key, "error": str(e)})

        # Prepare response
        response = {
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


def extract_zip_to_raw_bucket(
    source_bucket: str, zip_key: str, raw_bucket_name: str
) -> List[str]:
    """
    Download ZIP file from S3, extract contents, and upload to raw bucket.

    Args:
        source_bucket: Source S3 bucket containing the ZIP file
        zip_key: S3 key of the ZIP file
        raw_bucket_name: Short name of destination bucket

    Returns:
        List of extracted file keys uploaded to raw bucket

    Raises:
        ValueError: If inputs are empty or bucket name format is invalid
        ClientError: If S3 operations fail
        zipfile.BadZipFile: If the file is not a valid ZIP
    """
    # Validate inputs
    if not source_bucket or not zip_key or not raw_bucket_name:
        raise ValueError("source_bucket, zip_key, and raw_bucket_name must not be empty")

    # Resolve full bucket name (add prefix if needed)
    bucket_parts: List[str] = source_bucket.split("-")
    if len(bucket_parts) < 4:
        raise ValueError(f"Invalid source bucket name format: {source_bucket}")

    account: str = bucket_parts[0]
    project: str = bucket_parts[1]
    application: str = "-".join(bucket_parts[2:-1])
    raw_bucket: str = f"{account}-{project}-{application}-{raw_bucket_name}"

    logger.info(f"Target raw bucket: {raw_bucket}")

    extracted_files: List[str] = []

    try:
        # Download ZIP file from S3
        logger.info(f"Downloading ZIP file: s3://{source_bucket}/{zip_key}")
        zip_obj: Dict[str, Any] = s3_client.get_object(Bucket=source_bucket, Key=zip_key)
        zip_content: bytes = zip_obj["Body"].read()

        # Extract files from ZIP (testable business logic)
        files_to_upload: List[Tuple[str, bytes]] = extract_files_from_zip(zip_content)
        logger.info(f"Found {len(files_to_upload)} files to upload")

        # Upload each file to raw bucket
        for file_name, file_data in files_to_upload:
            try:
                logger.info(f"Uploading: {file_name} -> s3://{raw_bucket}/{file_name}")

                s3_client.put_object(
                    Bucket=raw_bucket,
                    Key=file_name,
                    Body=file_data,
                )

                extracted_files.append(file_name)
                logger.info(f"Successfully uploaded: {file_name}")

            except ClientError as e:
                logger.error(
                    f"Failed to upload file {file_name}: {str(e)}", exc_info=True
                )
                # Continue processing other files
                continue

        logger.info(f"Successfully extracted {len(extracted_files)} files from {zip_key}")
        return extracted_files

    except ClientError as e:
        logger.error(f"S3 operation failed: {str(e)}", exc_info=True)
        raise
    except zipfile.BadZipFile as e:
        logger.error(f"Invalid ZIP file {zip_key}: {str(e)}", exc_info=True)
        raise


def extract_files_from_zip(zip_content: bytes) -> List[Tuple[str, bytes]]:
    """
    Extract files from ZIP content.

    This function is separated for testability - it doesn't depend on AWS services.

    Args:
        zip_content: ZIP file as bytes

    Returns:
        List of tuples (filename, file_content) for non-directory, non-hidden files

    Raises:
        zipfile.BadZipFile: If content is not a valid ZIP file
        ValueError: If zip_content is empty
    """
    if not zip_content:
        raise ValueError("zip_content must not be empty")

    files: List[Tuple[str, bytes]] = []

    with zipfile.ZipFile(io.BytesIO(zip_content)) as zip_ref:
        file_list: List[str] = zip_ref.namelist()
        logger.info(f"Found {len(file_list)} entries in ZIP archive")

        for file_name in file_list:
            # Skip directories and hidden files
            if file_name.endswith("/") or file_name.startswith("."):
                logger.debug(f"Skipping directory or hidden file: {file_name}")
                continue

            # Read file from ZIP
            file_data: bytes = zip_ref.read(file_name)
            files.append((file_name, file_data))

    return files
