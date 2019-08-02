variable "namespace" {
    description = "the unique name of this workspace"
    type = string
}

variable "docker_directory" {
    description = "the directory of the Dockerfile and other source code you wish to build"
    type = string
}

variable "tags" {
    description = "a mapping of tags to assign to the resources"
    type = map(string)
    default = null
}