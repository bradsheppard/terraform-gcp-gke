variable "project_id" {}

variable "name" {}

variable "region" {}

variable "zone" {}

variable "vpc_id" {}

variable "subnet_id" {}

variable "accelerator_type" {}

variable "machine_type" {}

variable "min_nodes" {
  default = 1
}

variable "max_nodes" {
  default = 5
}

variable "gpu_machine_type" {}

variable "gpu_min_nodes" {
  default = 0
}

variable "gpu_max_nodes" {
  default = 1
}
