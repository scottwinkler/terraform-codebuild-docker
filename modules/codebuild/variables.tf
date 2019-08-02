variable "namespace" {
    type = string
}

variable "s3" {
    type = any
}

variable "entropy" {
    type = string
}

variable "tags" {
    type = map(string)
}