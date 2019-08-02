variable "namespace" {
    type = string
}

variable "codebuild_name" {
    type = string
}

variable "docker_directory" {
    type = string
}

variable "entropy" {
    type = string
}

variable "tags" {
    type = map(string)
}