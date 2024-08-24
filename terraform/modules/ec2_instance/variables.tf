variable "instance_type" {
  description = "The EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "The key name for the instance"
  type        = string
}

variable "subnet_id" {
  description = "The subnet ID"
  type        = string
}

variable "security_group_ids" {
  description = "The security group IDs"
  type        = list(string)
}

variable "user_data" {
  description = "The user data script"
  type        = string
}

variable "name" {
  description = "Name tag for the EC2 instance"
  type        = string
}
