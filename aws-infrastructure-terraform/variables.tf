variable "aws_region" {
  description = "AWS region for deployment."
  type        = string
}
variable "project_name" {
  description = "Prefix for names and tags."
  type        = string
  default     = "mohit-devops-lab"
  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,24}$", var.project_name))
    error_message = "Use 3-25 lowercase letters, digits, or hyphens; start with a letter."
  }
}
variable "environment" {
  description = "Environment tag."
  type        = string
  default     = "learning"
}
variable "instance_type" {
  description = "EC2 size; verify regional availability and pricing."
  type        = string
  default     = "t3.micro"
}
variable "root_volume_size" {
  description = "Encrypted gp3 root disk size in GiB."
  type        = number
  default     = 12
  validation {
    condition     = var.root_volume_size >= 8 && var.root_volume_size <= 100
    error_message = "root_volume_size must be between 8 and 100 GiB."
  }
}
variable "vpc_cidr" {
  description = "VPC IPv4 range."
  type        = string
  default     = "10.42.0.0/16"
}
variable "subnet_cidr" {
  description = "Public subnet IPv4 range."
  type        = string
  default     = "10.42.1.0/24"
}
