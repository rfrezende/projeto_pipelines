variable "region" {
  default = "us-east-1"
  type    = string
}

variable "availability_zone" {
  default = "us-east-1a"
  type = string
}

variable "usuario" {
  default = "admin"
  type    = string
}

variable "senha" {
  default = "senha!dificil"
  type    = string
}

variable "url_rabbitmq" {
  default = "localhost"
  type    = string
}

variable "url_redis" {
  default = "localhost"
  type    = string
}

variable "url_minio" {
  default = "localhost"
  type    = string
}