resource "random_string" "rand" {
  length  = 8
  special = false
  upper   = false
}

module "codebuild" {
  source    = "./modules/codebuild"
  namespace = var.namespace
  tags      = var.tags

  s3      = module.s3.s3
  entropy = random_string.rand.result
}

module "s3" {
  source           = "./modules/s3"
  namespace        = var.namespace
  docker_directory = var.docker_directory
  tags             = var.tags

  codebuild_name = module.codebuild.codebuild_name
  entropy        = random_string.rand.result
}
