variable "aws_region" {
  default = "ap-southeast-1"
}

variable "environment" {
  default = "devtoprd"
}

variable "vpc_cidr" {
  default     = "10.0.0.0/16"
  description = "CIDR block of the vpc"
}

variable "public_subnets_cidr" {
  type        = list(any)
  default     = ["10.0.0.0/28", "10.0.16.0/28"]
  description = "CIDR block for Public Subnet"
}

variable "private_subnets_cidr_az_a" {
  type        = list(any)
  default     = ["10.0.128.0/26", "10.0.160.0/26", "10.0.200.0/28"]
  description = "CIDR block for Private Subnet"
}

variable "private_subnets_cidr_az_b" {
  type        = list(any)
  default     = ["10.0.144.0/26", "10.0.176.0/26", "10.0.201.0/28"]
} 

variable "ami_id" {
  default = "ami-0474ac020852b87a9"
}

variable "disk_size" {
  default = "30"
}
