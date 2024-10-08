"""
Unzip lambda intended to unzip a .ZIP file such that the individual
CSV files contained within it are uploaded to separate date/time partitions.

Assumed to be triggered via an S3 bucket notification, hence we're assuming
structure and contents of the event passed through to the handler.

REQUIRED environment variables:
- ERROR_SNS_TOPIC: ARN of SNS topic to notify on failure
- TARGET_PREFIX: Prefix to use when unzipping files
- TARGET_BUCKET: Bucket to unzip files to

OPTIONAL environment variables:
- LOG_LEVEL: Logging level for the lambda, permissible values are:
DEBUG, INFO, WARNING, ERROR, CRITICAL.
"""

# Standard modules
import logging
import os
import json
import ntpath
import zipfile
import io

# Third-party modules
import boto3

LOGGER: logging.Logger = logging.getLogger(__name__)
ERROR_SNS_TOPIC: str = os.environ['ERROR_SNS_TOPIC']
TARGET_PREFIX: str = "dogs/daily"
TARGET_BUCKET_NAME: str = os.environ['TARGET_BUCKET_NAME']

logging_level: str = os.environ.get("LOG_LEVEL")
LOGGER.setLevel(logging_level if logging_level is not None else "INFO")


def get_bucket_name_from_event(event: any) -> str:
    """
    Helper function to simply discover bucket name from event.

    :param event: Raw event object passed through to lambda handler.
    :return: The bucket name. Raises IndexError if no bucket name was found.
    """
    bucket_name: str = event['Records'][0]['s3']['bucket']['name']
    LOGGER.info(f"Bucket Name = {bucket_name}")
    return bucket_name


def get_file_key_from_event(event: any) -> str:
    """
    Helper function to simply discover file key from event.

    :param event: Raw event passed through to lambda handler.
    :return: The bucket name. Raises IndexError if no bucket name was found.
    """
    file_key: str = event['Records'][0]['s3']['object']['key']
    LOGGER.info(f"file_key = {file_key}")
    return file_key


def send_error_notification(message, message_type) -> None:
    """
    Helper function to send error notification to SNS topic.

    :param message: Message to be sent to SNS topic.
    :param message_type: Alarm name to be sent to SNS topic.
    :return:
    """
    sns_client = boto3.Session().client('sns', verify=False)
    message_dictionary = {
        "description": str(message),
        "alarm_name": str(message_type)
    }
    sns_client.publish(
        TopicArn=ERROR_SNS_TOPIC,
        Subject="Error in unzip lambda function.",
        Message=json.dumps(message_dictionary),
        MessageStructure="json",
    )


def get_date_partition(file_key) -> (str, str, str):
    """
    Helper function to extract date partition from file key.

    :param file_key: File key to extract partitions from
    :return: Tuple of year, month, day. Raises IndexError if files are not in correct format.
    """
    LOGGER.info(f"get_date_partition for file_key = {file_key}")
    head, file_name = ntpath.split(file_key)

    year = file_name[0:4]
    month = file_name[4:6]
    day = file_name[6:8]

    LOGGER.info(f"year = {year}, month = {month}, day = {day}")

    return year, month, day


def unzip_file(source_bucket: str,
               source_file: str,
               destination_bucket: str,
               destination_prefix: str
               ) -> bool:
    """
    Helper function to unzip a ZIP file.

    :param source_bucket: Bucket to read source_file from.
    :param source_file: Fully qualified path to the ZIP file.
    :param destination_bucket: Bucket to write unzipped file(s) to.
    :param destination_prefix: Prefix within destination_bucket to write unzipped files to.
    :return: True if successful, else False.
    """
    s3_client = boto3.Session().client('s3')
    zip_object = s3_client.get_object(Bucket=source_bucket, Key=source_file)

    buffer = io.BytesIO(zip_object['Body'].read())
    zip_buffer = zipfile.ZipFile(buffer)

    csv_files = list(filter(lambda f: f.endswith('.csv'), zip_buffer.namelist()))

    failed = False
    counter = 0

    while counter < len(csv_files) and failed is False:
        filename = csv_files[counter].split("/")[-1]
        year, month, day = get_date_partition(filename)
        destination_path = "/".join([
            destination_prefix,
            "_year=" + str(year),
            "_month=" + str(month),
            "_day=" + str(day),
            "viewings"
        ]
        )

        try:
            s3_client.upload_fileobj(
                zip_buffer.open(filename),
                Bucket=destination_bucket,
                Key=destination_path
            )
            LOGGER.info(f"Successfully unzipped {filename}")
        except Exception as e:
            failed = True
            LOGGER.error(f"Failed to unzip {filename}")
            LOGGER.error(e)
            raise RuntimeError(f"Unable to unzip {filename}")
        finally:
            counter += 1

    return not failed


def lambda_handler(event, context) -> None:
    """
    Main entrypoint for our lambda.

    :param event: Magic object passed in by lambda
    :param context: Magic object passed in by lambda
    :return: None
    """
    LOGGER.info(context)
    LOGGER.info(event)

    try:
        source_bucket: str = get_bucket_name_from_event(event)
        source_file: str = get_file_key_from_event(event)
        unzip_success = unzip_file(source_bucket, source_file, TARGET_BUCKET_NAME, TARGET_PREFIX)
        if not unzip_success:
            raise RuntimeError("Unable to successfully unzip file.")
    except Exception as error:
        LOGGER.error(error)
        send_error_notification(error, "Failure in unzip process")