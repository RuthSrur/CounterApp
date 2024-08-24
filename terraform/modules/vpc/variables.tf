variable "cidr_block" {
  description = "The CIDR block for the VPC."
  type        = string
}

variable "name" {
  description = "The name tag for the VPC."
  type        = string
}

variable "subnet_cidr_block" {
  description = "The CIDR block for the subnet."
  type        = string
}

variable "subnet_name" {
  description = "The name tag for the subnet."
  type        = string
}

variable "igw_name" {
  description = "The name tag for the Internet Gateway."
  type        = string
}

variable "route_table_name" {
  description = "The name tag for the Route Table."
  type        = string
}
