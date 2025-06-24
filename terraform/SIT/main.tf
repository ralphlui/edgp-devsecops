terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.aws_region
}

locals {
  availability_zones = ["${var.aws_region}a", "${var.aws_region}b"]
  resource_types     = ["web", "app", "db"]
}

# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "my-vpc-edgp"
    Environment = var.environment
  }
}

# Create a public subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.public_subnets_cidr)
  cidr_block              = element(var.public_subnets_cidr, count.index)
  availability_zone       = element(local.availability_zones, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name        = "my-subnet-public${count.index+1}-${element(local.availability_zones, count.index)}"
    Environment = var.environment
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/app-cluster-1" = "shared"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet_a" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.private_subnets_cidr_az_a)
  cidr_block              = element(var.private_subnets_cidr_az_a, count.index)
  availability_zone       = local.availability_zones[0] 
  map_public_ip_on_launch = false

  tags = {
    Name        = "my-subnet-private${count.index+1}-${element(local.resource_types, count.index)}-${local.availability_zones[0]}"
    Environment = var.environment
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${element(local.resource_types, count.index)}-cluster-1" = "owned"
  }
}

resource "aws_subnet" "private_subnet_b" {
  vpc_id                  = aws_vpc.vpc.id
  count                   = length(var.private_subnets_cidr_az_b)
  cidr_block              = element(var.private_subnets_cidr_az_b, count.index)
  availability_zone       = local.availability_zones[1]
  map_public_ip_on_launch = false

  tags = {
    Name        = "my-subnet-private${count.index+1}-${element(local.resource_types, count.index)}-${local.availability_zones[1]}"
    Environment = var.environment
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/${element(local.resource_types, count.index)}-cluster-1" = "owned"
  }
}

# Internet gateway
resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    "Name"        = "my-igw"
    "Environment" = var.environment
  }
}

# Routing tables to route traffic for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name        = "my-rtb-public1"
    Environment = var.environment
  }
}

# Routing tables to route traffic for Private Subnet
resource "aws_route_table" "private_a" {
  vpc_id = aws_vpc.vpc.id
  count  = 2
  tags = {
    Name        = "my-rtb-private${count.index+1}-${element(local.resource_types, count.index)}-${local.availability_zones[0]}"
    Environment = var.environment
  }
}

resource "aws_route_table" "private_b" {
  vpc_id = aws_vpc.vpc.id 
  count  = 2
  tags = {
    Name        = "my-rtb-private${count.index+1}-${element(local.resource_types, count.index)}-${local.availability_zones[1]}"
    Environment = var.environment
  } 
} 

resource "aws_route_table" "private_c" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name        = "my-rtb-private-${local.resource_types[2]}-${local.availability_zones[0]}"
    Environment = var.environment
  }
}

# Route for Internet Gateway
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

# Route table associations for both Public subnet
resource "aws_route_table_association" "public" {
  count          = length(var.public_subnets_cidr)
  subnet_id      = element(aws_subnet.public_subnet[*].id, count.index)
  route_table_id = aws_route_table.public.id
}

# Route table associations for both Private subnet
resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_subnet_a[0].id
  route_table_id = aws_route_table.private_a[0].id
}

resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_subnet_a[1].id
  route_table_id = aws_route_table.private_a[1].id
}

resource "aws_route_table_association" "private_3" {
  subnet_id      = aws_subnet.private_subnet_a[2].id
  route_table_id = aws_route_table.private_c.id
}

resource "aws_route_table_association" "private_4" {
  subnet_id      = aws_subnet.private_subnet_b[0].id
  route_table_id = aws_route_table.private_b[0].id
}

resource "aws_route_table_association" "private_5" {
  subnet_id      = aws_subnet.private_subnet_b[1].id
  route_table_id = aws_route_table.private_b[1].id
}

resource "aws_route_table_association" "private_6" {
  subnet_id      = aws_subnet.private_subnet_b[2].id
  route_table_id = aws_route_table.private_c.id
}
