output "codebuild_name" {
    value = aws_codebuild_project.codebuild_project.name
}

output "image_url" {
    value = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${data.aws_region.current.name}.amazonaws.com/${aws_ecr_repository.ecr_repository.name}:latest"
}