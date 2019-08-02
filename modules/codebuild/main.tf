data "aws_region" "current" {}

data "aws_caller_identity" "current" {}

# codebuild iam permissions
resource "aws_iam_role" "iam_role" {
  name = "${var.namespace}-codebuild-${var.entropy}"
  tags = var.tags
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "codebuild.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF


}

resource "aws_iam_role_policy" "example" {
  role = aws_iam_role.iam_role.name

  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:*"
      ],
      "Resource": [
        "${var.s3.arn}",
        "${var.s3.arn}/*"
      ]
    },
    {
      "Effect": "Allow",
      "Resource": [
        "*"
      ],
      "Action": [
        "ecr:*"
      ]
    }
  ]
}
POLICY
}

# the codebuild project
resource "aws_codebuild_project" "codebuild_project" {
  name          = "${var.namespace}-codebuild-project-${var.entropy}"
  build_timeout = "5"
  service_role  = aws_iam_role.iam_role.arn
  tags = var.tags
  artifacts {
    type = "NO_ARTIFACTS"
  }

  cache {
    type     = "S3"
    location = "${var.namespace}-codebuild-shenanigans"
  }

  environment {
    compute_type    = "BUILD_GENERAL1_SMALL"
    image           = "aws/codebuild/standard:2.0"
    type            = "LINUX_CONTAINER"
    privileged_mode = true
  }

  source {
    type     = "S3"
    location = "${var.s3.bucket}/codebuild.zip"
    buildspec = local.buildspec
  }
}

locals {
  buildspec = templatefile("${path.module}/buildspec.yaml", {
      AWS_DEFAULT_REGION = data.aws_region.current.name
      AWS_ACCOUNT_ID     = data.aws_caller_identity.current.account_id
      IMAGE_REPO_NAME    = aws_ecr_repository.ecr_repository.name
      IMAGE_TAG          = "latest"
    })
}

# final resting place for images
resource "aws_ecr_repository" "ecr_repository" {
  name = "${var.namespace}-ecr-${var.entropy}"
  tags = var.tags
}
