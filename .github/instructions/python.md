# Python Code Generation Instructions

This file provides GitHub Copilot with patterns, conventions, and standards for generating Python code in this repository, specifically for Lambda functions and related utilities.

**Key Principle:** Write clean, maintainable, explicitly typed Python code with comprehensive logging and traceability.

---

## General Python Standards

### Code Quality Tools

All Python code in this repository will be validated with:
- **flake8**: Linting and style enforcement
- **bandit**: Security vulnerability detection
- **pytest**: Unit testing and code coverage
- **Black**: Code formatting (88 character line length)

**When generating code:**
- Write code that will pass flake8 checks
- Avoid patterns flagged by bandit (hardcoded secrets, unsafe functions, etc.)
- Structure code to be testable with pytest
- Follow Black formatting standards

### Type Hints and Explicit Typing

**Always include explicit type hints on ALL variables:**

```python
from typing import Any, Dict, List, Optional, Tuple

def process_data(
    input_data: Dict[str, Any],
    config: Optional[Dict[str, str]] = None
) -> Tuple[List[str], int]:
    """Process input data and return results."""
    # Explicit typing for local variables
    results: List[str] = []
    count: int = 0

    for item in input_data.get("items", []):
        item_name: str = item["name"]
        item_value: int = item.get("value", 0)

        if item_value > 0:
            results.append(item_name)
            count += 1

    return results, count
```

**Rules:**
- **ALL** function parameters must have type hints
- **ALL** functions must have explicit return type annotations
- **ALL** local variables should have explicit type hints (especially important ones)
- Use `typing` module for complex types (Dict, List, Optional, Tuple, etc.)
- Use `None` for functions that don't return values
- Use `Any` sparingly and only when type is truly dynamic

**Examples:**
```python
# Good: Explicit types everywhere
bucket_name: str = event["bucket"]
file_count: int = len(files)
config: Dict[str, str] = load_config()
items: List[str] = []

# Bad: No type hints
bucket_name = event["bucket"]
file_count = len(files)
config = load_config()
items = []
```

### Documentation Requirements

**Docstrings are mandatory for:**
1. All modules (at top of file)
2. All functions and methods
3. All classes

**Format - Google Style:**

```python
"""
Module-level docstring explaining the module's purpose.

This module provides functionality for processing S3 events
and extracting data from various file formats.
"""

def function_name(param1: str, param2: int) -> Dict[str, Any]:
    """
    Brief one-line description of what the function does.

    More detailed explanation if needed, describing the overall
    behavior, algorithm, or important details.

    Args:
        param1: Description of first parameter
        param2: Description of second parameter

    Returns:
        Dictionary containing processed results with keys:
        - 'status': Processing status
        - 'count': Number of items processed

    Raises:
        ValueError: If param1 is empty
        ClientError: If AWS API call fails

    Example:
        >>> result = function_name("test", 42)
        >>> print(result['status'])
        'success'
    """
    result: Dict[str, Any] = {}
    # Implementation
    return result
```

### Input Validation

**Use simple validation with explicit checks:**

```python
def process_file(bucket: str, key: str, max_size: int = 100_000_000) -> bytes:
    """
    Process file from S3.

    Args:
        bucket: S3 bucket name
        key: S3 object key
        max_size: Maximum file size in bytes

    Returns:
        File contents as bytes

    Raises:
        ValueError: If inputs are invalid
        ClientError: If S3 operations fail
    """
    # Validate inputs
    if not bucket or not key:
        raise ValueError("bucket and key must not be empty")

    if max_size <= 0:
        raise ValueError(f"max_size must be positive, got {max_size}")

    # Prevent path traversal
    if ".." in key or key.startswith("/"):
        raise ValueError(f"Invalid S3 key format: {key}")

    # Implementation
    content: bytes = download_from_s3(bucket, key)
    return content
```

### AWS Lambda Powertools for Event Handling

**Use AWS Lambda Powertools for structured event parsing:**

```python
from aws_lambda_powertools.utilities.data_classes import S3Event, event_source
from typing import Any, Dict

@event_source(data_class=S3Event)
def handler(event: S3Event, context: Any) -> Dict[str, Any]:
    """
    Lambda handler for S3 events.

    Args:
        event: S3 event data class from Lambda Powertools
        context: Lambda context object

    Returns:
        Response dictionary with processing results

    Raises:
        ValueError: If configuration is invalid
    """
    processed: List[str] = []

    for record in event.records:
        bucket_name: str = record.s3.bucket.name
        object_key: str = record.s3.get_object.key

        # Process the object
        result: str = process_s3_object(bucket_name, object_key)
        processed.append(result)

    return {"statusCode": 200, "processed": processed}
```

**Configuration loading with validation:**

```python
def get_config() -> Dict[str, str]:
    """
    Load and validate configuration from environment variables.

    Returns:
        Dictionary containing validated configuration

    Raises:
        ValueError: If required variables are missing or invalid
    """
    raw_bucket: str = os.environ.get("RAW_BUCKET", "")
    if not raw_bucket:
        raise ValueError("RAW_BUCKET environment variable is required")

    log_level: str = os.environ.get("LOG_LEVEL", "INFO").upper()
    allowed_levels: List[str] = ["DEBUG", "INFO", "WARNING", "ERROR", "CRITICAL"]
    if log_level not in allowed_levels:
        raise ValueError(f"LOG_LEVEL must be one of {allowed_levels}")

    return {"raw_bucket": raw_bucket, "log_level": log_level}
```

### Exception Handling

**Always handle exceptions explicitly:**

```python
from botocore.exceptions import ClientError
import logging

logger = logging.getLogger(__name__)


def download_from_s3(bucket: str, key: str) -> bytes:
    """
    Download file from S3 with proper error handling.

    Args:
        bucket: S3 bucket name
        key: S3 object key

    Returns:
        File contents as bytes

    Raises:
        ClientError: If S3 operation fails
        ValueError: If bucket or key is empty
    """
    if not bucket or not key:
        raise ValueError("Bucket and key must not be empty")

    try:
        response = s3_client.get_object(Bucket=bucket, Key=key)
        return response["Body"].read()

    except ClientError as e:
        error_code = e.response.get("Error", {}).get("Code", "Unknown")
        logger.error(
            f"Failed to download s3://{bucket}/{key}: {error_code}",
            exc_info=True
        )
        raise

    except Exception as e:
        logger.error(f"Unexpected error downloading from S3: {str(e)}", exc_info=True)
        raise
```

**Exception handling patterns:**

1. **Be specific:** Catch specific exceptions, not bare `except:`
2. **Log before re-raising:** Always log with context before re-raising
3. **Use exc_info=True:** Include stack trace in error logs
4. **Document raised exceptions:** List all exceptions in docstring
5. **Clean up resources:** Use context managers or try/finally

**Context managers for cleanup:**

```python
import tempfile
from pathlib import Path


def process_with_tempfile(data: bytes) -> Dict[str, Any]:
    """
    Process data using temporary file.

    Args:
        data: Binary data to process

    Returns:
        Processing results

    Raises:
        IOError: If file operations fail
    """
    with tempfile.NamedTemporaryFile(mode="wb", delete=False) as tmp:
        try:
            tmp.write(data)
            tmp.flush()

            # Process the temp file
            result = process_file(Path(tmp.name))
            return result

        finally:
            # Always clean up temp file
            Path(tmp.name).unlink(missing_ok=True)
```

### Logging Standards

**Configure logging properly:**

```python
import logging
import os

# Module-level logger
LOG_LEVEL = os.environ.get("LOG_LEVEL", "INFO")
logger = logging.getLogger(__name__)
logger.setLevel(LOG_LEVEL)

# For Lambda handlers, configure root logger
def setup_lambda_logging() -> None:
    """Configure logging for Lambda execution."""
    root_logger = logging.getLogger()
    root_logger.setLevel(LOG_LEVEL)

    # Add structured logging if needed
    handler = logging.StreamHandler()
    formatter = logging.Formatter(
        "%(asctime)s - %(name)s - %(levelname)s - %(message)s"
    )
    handler.setFormatter(formatter)
    root_logger.addHandler(handler)
```

**Logging best practices:**

```python
# Good: Structured logging with context
logger.info(
    "Processing file",
    extra={
        "bucket": bucket_name,
        "key": object_key,
        "size": file_size
    }
)

# Good: Use f-strings for log messages
logger.error(f"Failed to process {key}: {error_message}")

# Good: Different levels for different situations
logger.debug(f"Detailed processing info: {details}")
logger.info(f"Successfully processed {count} files")
logger.warning(f"Skipping invalid file: {filename}")
logger.error(f"Processing failed: {error}", exc_info=True)

# Bad: String concatenation
logger.info("Processing " + bucket + "/" + key)

# Bad: No context in errors
logger.error("Failed")
```

### Security Standards

**Never hardcode secrets:**

```python
# Bad
API_KEY = "sk-1234567890abcdef"

# Good - Use environment variables
API_KEY = os.environ["API_KEY"]

# Good - Use AWS Secrets Manager
import boto3

def get_secret(secret_name: str) -> Dict[str, Any]:
    """Retrieve secret from AWS Secrets Manager."""
    client = boto3.client("secretsmanager")
    response = client.get_secret_value(SecretId=secret_name)
    return json.loads(response["SecretString"])
```

**Input validation:**

```python
import re


def validate_s3_key(key: str) -> None:
    """
    Validate S3 key format.

    Args:
        key: S3 object key to validate

    Raises:
        ValueError: If key format is invalid
    """
    # Prevent path traversal
    if ".." in key or key.startswith("/"):
        raise ValueError(f"Invalid S3 key format (path traversal): {key}")

    # Validate characters
    if not re.match(r'^[a-zA-Z0-9\-_./]+$', key):
        raise ValueError(f"S3 key contains invalid characters: {key}")
```

**Safe file operations:**

```python
from pathlib import Path


def safe_file_write(base_dir: Path, filename: str, content: bytes) -> None:
    """
    Safely write file preventing path traversal.

    Args:
        base_dir: Base directory for file operations
        filename: Name of file to write
        content: File content

    Raises:
        ValueError: If filename attempts path traversal
        IOError: If file write fails
    """
    # Validate inputs
    if not filename or not content:
        raise ValueError("filename and content must not be empty")

    # Resolve paths and validate
    base_dir_resolved: Path = base_dir.resolve()
    target_path: Path = (base_dir_resolved / filename).resolve()

    # Ensure target is within base_dir
    if not str(target_path).startswith(str(base_dir_resolved)):
        raise ValueError(f"Path traversal detected: {filename}")

    # Write safely
    target_path.parent.mkdir(parents=True, exist_ok=True)
    target_path.write_bytes(content)
```

---

## Lambda-Specific Patterns

### Lambda Handler Structure

```python
"""
Lambda function for [purpose].

This function is triggered by [trigger type] and performs [description].
"""

import logging
import os
from typing import Any, Dict, List

import boto3
from aws_lambda_powertools.utilities.data_classes import S3Event, event_source
from botocore.exceptions import ClientError

# Configure logging
LOG_LEVEL: str = os.environ.get("LOG_LEVEL", "INFO")
logger = logging.getLogger()
logger.setLevel(LOG_LEVEL)

# Initialize AWS clients (outside handler for reuse)
s3_client = boto3.client("s3")


def get_config() -> Dict[str, str]:
    """
    Load and validate configuration from environment variables.

    Returns:
        Dictionary containing validated configuration

    Raises:
        ValueError: If required environment variables are missing or invalid
    """
    target_bucket: str = os.environ.get("TARGET_BUCKET", "")
    if not target_bucket:
        raise ValueError("TARGET_BUCKET environment variable is required")

    return {"target_bucket": target_bucket}


@event_source(data_class=S3Event)
def handler(event: S3Event, context: Any) -> Dict[str, Any]:
    """
    Lambda handler for [purpose].

    Args:
        event: S3 event data class from Lambda Powertools
        context: Lambda context object

    Returns:
        Response dictionary with:
        - statusCode: HTTP status code
        - processed_count: Number of items processed
        - failed_count: Number of failures

    Raises:
        ValueError: If configuration is invalid
        Exception: If processing fails critically
    """
    logger.info(f"Received S3 event with {len(event.records)} record(s)")

    try:
        # Load and validate configuration
        config: Dict[str, str] = get_config()

        processed: List[str] = []
        failed: List[str] = []

        # Process each record
        for record in event.records:
            bucket_name: str = record.s3.bucket.name
            object_key: str = record.s3.get_object.key

            try:
                result: str = process_object(bucket_name, object_key, config)
                processed.append(result)
            except Exception as e:
                logger.error(f"Failed to process {object_key}: {str(e)}", exc_info=True)
                failed.append(object_key)

        # Return response
        return {
            "statusCode": 200 if not failed else 207,
            "processed_count": len(processed),
            "failed_count": len(failed),
        }

    except Exception as e:
        logger.error(f"Handler execution failed: {str(e)}", exc_info=True)
        raise


def process_object(bucket: str, key: str, config: Dict[str, str]) -> str:
    """
    Process S3 object.

    Args:
        bucket: S3 bucket name
        key: S3 object key
        config: Configuration dictionary

    Returns:
        Processing result

    Raises:
        ClientError: If S3 operations fail
    """
    # Implementation
    pass
```

---

## Testing Guidelines

### Write Testable Code

**Separate business logic from AWS SDK calls:**

```python
# Good: Testable
def extract_files_from_zip(zip_content: bytes) -> List[Tuple[str, bytes]]:
    """
    Extract files from ZIP content.

    Args:
        zip_content: ZIP file as bytes

    Returns:
        List of tuples (filename, file_content)

    Raises:
        zipfile.BadZipFile: If content is not valid ZIP
        ValueError: If zip_content is empty
    """
    if not zip_content:
        raise ValueError("zip_content must not be empty")

    import zipfile
    import io

    files: List[Tuple[str, bytes]] = []

    with zipfile.ZipFile(io.BytesIO(zip_content)) as zf:
        for name in zf.namelist():
            if not name.endswith("/"):
                file_data: bytes = zf.read(name)
                files.append((name, file_data))

    return files


def process_s3_zip(bucket: str, key: str, target_bucket: str) -> List[str]:
    """
    Download and extract ZIP from S3.

    Args:
        bucket: S3 bucket name
        key: S3 object key
        target_bucket: Destination bucket for extracted files

    Returns:
        List of extracted filenames

    Raises:
        ValueError: If inputs are invalid
        ClientError: If S3 operations fail
    """
    # Validate inputs
    if not bucket or not key or not target_bucket:
        raise ValueError("bucket, key, and target_bucket must not be empty")

    # Download from S3
    zip_obj: Dict[str, Any] = s3_client.get_object(Bucket=bucket, Key=key)
    zip_content: bytes = zip_obj["Body"].read()

    # Extract (testable without S3)
    files: List[Tuple[str, bytes]] = extract_files_from_zip(zip_content)

    # Upload to S3
    uploaded: List[str] = upload_files_to_s3(files, target_bucket)
    return uploaded
```

### Pytest-Ready Structure

```python
# Use dependency injection for testing
class S3Processor:
    """Process S3 files with injectable client."""

    def __init__(self, s3_client=None):
        """
        Initialize processor.

        Args:
            s3_client: S3 client (defaults to boto3 client)
        """
        self.s3_client = s3_client or boto3.client("s3")

    def download_file(self, bucket: str, key: str) -> bytes:
        """Download file from S3."""
        response = self.s3_client.get_object(Bucket=bucket, Key=key)
        return response["Body"].read()
```

---

## Code Style Summary

**Naming Conventions:**
- Functions/variables: `snake_case`
- Classes: `PascalCase`
- Constants: `UPPER_SNAKE_CASE`
- Private methods: `_leading_underscore`

**Import Organization:**
```python
# Standard library
import json
import logging
import os
from typing import Any, Dict, List

# Third-party
import boto3
from botocore.exceptions import ClientError
from pydantic import BaseModel, Field

# Local/application
from .utils import helper_function
```

**Line Length:**
- Maximum 88 characters (Black standard)
- Break long function calls/definitions across lines

**Formatting:**
- Use Black formatter
- 4 spaces for indentation
- Two blank lines between top-level functions/classes
- One blank line between methods

---

**Remember:** Code quality tools will enforce these standards. Write code that passes flake8, bandit, and has good pytest coverage from the start.
