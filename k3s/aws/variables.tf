// Region

variable "region" {
  type    = string
  default = "us-east-1"
}

// VPC CIDR

variable "vpc_cidr" {
  type = string
  default = "10.0.0.0/16"
}

// Subnet CIDRs

variable "private_subnet_1_cidr" {
  type = string
  default = "10.0.1.0/24"
}

variable "private_subnet_2_cidr" {
  type = string
  default = "10.0.2.0/24"
}

variable "public_subnet_1_cidr" {
  type = string
  default = "10.0.11.0/24"
}

variable "public_subnet_2_cidr" {
  type = string
  default = "10.0.12.0/24"
}

variable "ami_id" {
  type = string
  default = "ami-0ac80df6eff0e70b5"
}

variable "k3s_server_count" {
  type = number
}

variable "cluster_name" {
  type = string
}

variable "k3s_server_size" {
  type = string
  default = "t2.xlarge"
}

variable "k3s_agent_count" {
  type = number
}

variable "k3s_agent_size" {
  type = string
  default = "t2.xlarge"
}

variable "db_username" {
  type = string
}

variable "db_password" {
  type = string
}

variable "public_ssh_key" {
  type = string
}

variable "key_s3_bucket_name" {
  type = string
}

variable "configure_aws_provider" {
  type = string
  default = "true"
}
