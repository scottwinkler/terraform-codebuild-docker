
import json
import boto3
import os

client = boto3.client('codebuild')


def lambda_handler(event, context):

    for record in event['Records']:
        client.start_build(projectName=os.environ["CODEBUILD_NAME"])
        body = json.loads(record['body'])
