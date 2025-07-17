import boto3

# First you need to configure your AWS credentials.

s3 = boto3.client('s3')

bucket_name = 'boto312131231'
file_name = 'file.txt'


def upload_file(bucket_name, file_name, object_name=None):
    """Upload a file to an S3 bucket."""
    if object_name is None:
        object_name = file_name
    s3.upload_file(file_name, bucket_name, object_name)

upload_file(bucket_name,file_name)