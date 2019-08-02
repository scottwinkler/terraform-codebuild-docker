# terraform-codebuild-docker
this terraform code deploys a codebuild project, and then triggers a build for build a Docker image. The resulting image is stored in ECR.

inputs
- docker_directory (required) - path to your docker folder you would like to build
- namespace (required) - for naming the resources a certain way
- tags (optional) - a mapping of tags you'd like to apply to the resources
outputs
- image_url - a string url for where to find the image in ECR

## How?!?
The steps involved are:
1) An object is uploaded to S3
2) That object triggers a lambda function via a cloudwatch rule
3) The lambda function kicks off a codebuild job
4) Codebuild reads from the source code stored in the S3 bucket to build a Docker image
and store that in ECR
5) The image can later be used within the same Terraform project to deploy services, for example to ECS or Fargate