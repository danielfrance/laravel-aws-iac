
variable "environment" {
  default = "dev"
}
variable "project_id" {}
variable "region" {
  default = "us-east-1"
}

variable "vpc_cidr" {}

variable "db_instance_type" {}
variable "db_name" {}
variable "db_user" {}
variable "db_port" {}
variable "db_password" {}
variable "db_engine" {}
variable "db_engine_version" {}
variable "db_allocated_storage" {}
variable "db_max_allocated_storage" {}


variable "authorized_ips" {
  type = list(string)
}

variable "cluster_name" {}


variable "tfstate_bucket" {}

variable "logs_bucket" {}

variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "node_max_size" {}
variable "node_min_size" {}
variable "node_size" {}

variable "eks_access_entries" {
  description = "List of IAM users/roles to be granted EKS access."
  type = list(object({
    name          = string
    principal_arn = string
  }))
}

variable "default_AWS_profile" {}

variable "redis_cluster_id" {
  description = "The ID of the Redis ElastiCache cluster."
  type        = string
}

variable "redis_engine" {
  default     = "redis"
  description = "The engine to use for the Redis ElastiCache cluster."
  type        = string
  validation {
    condition     = contains(["redis", "memcached", "valkey"], var.redis_engine)
    error_message = "Invalid Redis engine. Must be one of: redis, memcached, valkey."
  }
}

variable "redis_parameter_group_family" {
  default     = "redis7"
  description = "The parameter group family to use for the Redis ElastiCache cluster."
  type        = string
  validation {
    condition     = contains(["redis7", "memcached1.6", "valkey7"], var.redis_parameter_group_family)
    error_message = "Invalid Redis parameter group family. Must be one of: redis7, memcached1.6, valkey7."
  }
}

variable "create_redis_cluster" {
  default = true
}

variable "create_redis_replication_group" {
  default = false
}
