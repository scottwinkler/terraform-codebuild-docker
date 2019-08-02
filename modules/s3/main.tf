# iam role for lambda function
data "aws_iam_policy_document" "lambda_assume_role_policy_document" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "lambda_iam_policy_document" {
  statement {
    effect    = "Allow"
    actions   = ["logs:*", "codebuild:StartBuild"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "lambda_iam_policy" {
  name   = "${var.namespace}-lambda-iam-policy-${var.entropy}"
  path   = "/"
  policy = data.aws_iam_policy_document.lambda_iam_policy_document.json
}

resource "aws_iam_role" "lambda_role" {
  name               = "${var.namespace}-lambda_role-${var.entropy}"
  path               = "/"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role_policy_document.json
  tags = var.tags
}

resource "aws_iam_policy_attachment" "lambda_iam_policy_role_attachment" {
  name       = "${var.namespace}-lambda_iam_policy_role_attachment-${var.entropy}"
  roles      = [aws_iam_role.lambda_role.name]
  policy_arn = aws_iam_policy.lambda_iam_policy.arn
}

# s3 bucket for Dockerfile and lambda source code
resource "aws_s3_bucket" "s3_bucket" {
  bucket = "${var.namespace}-codebuild-shenanigans"
  acl    = "private"
  tags = var.tags
}

# zip up code for lambda function and put in bucket
data "archive_file" "code_package" {
  type        = "zip"
  source_dir  = "${path.module}/code"
  output_path = "${path.module}/code.zip"
}

resource "aws_s3_bucket_object" "s3_object" {
  bucket = aws_s3_bucket.s3_bucket.bucket
  key    = basename(data.archive_file.code_package.output_path)
  source = data.archive_file.code_package.output_path
  etag   = filemd5(data.archive_file.code_package.output_path)
  tags = var.tags
}

# create the lambda function
resource "aws_lambda_function" "lambda_function" {
  s3_bucket        = aws_s3_bucket.s3_bucket.bucket
  s3_key           = aws_s3_bucket_object.s3_object.key
  source_code_hash = filemd5(data.archive_file.code_package.output_path)
  function_name    = "${var.namespace}-lambda_function-${var.entropy}"
  description      = "Kicks off a codebuild job"
  handler          = "main.lambda_handler"
  role             = aws_iam_role.lambda_role.arn
  memory_size      = 256
  runtime          = "python3.7"
  timeout          = 60
  environment {
    variables = {
      CODEBUILD_NAME = var.codebuild_name
    }
  }
  tags = var.tags
}

# trigger lambda function when object is put in s3
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.s3_bucket.bucket
  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda_function.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_permission" "allow_bucket" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda_function.arn
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.s3_bucket.arn
}

# put the object in the bucket and kick off build
data "archive_file" "dockerfile_package" {
  type        = "zip"
  source_dir  = var.docker_directory
  output_path = "${path.module}/codebuild.zip"
}

resource "aws_s3_bucket_object" "object" {
  depends_on = [aws_s3_bucket_notification.bucket_notification, aws_lambda_permission.allow_bucket]
  bucket     = aws_s3_bucket.s3_bucket.bucket
  key        = basename(data.archive_file.dockerfile_package.output_path)
  source     = data.archive_file.dockerfile_package.output_path
  etag       = filemd5(data.archive_file.dockerfile_package.output_path)
  tags = var.tags
}