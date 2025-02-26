resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "eks-vpc"
  }
}

# Public subnets
resource "aws_subnet" "public_1" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public-subnet-1"
    "kubernetes.io/role/elb" = "1"
  }
}

resource "aws_subnet" "public_2" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1b"
  map_public_ip_on_launch = true
  
  tags = {
    Name = "public-subnet-2"
    "kubernetes.io/role/elb" = "1"
  }
}

# Private subnets
resource "aws_subnet" "private_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "us-east-1a"
  
  tags = {
    Name = "private-subnet-1"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

resource "aws_subnet" "private_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "us-east-1b"
  
  tags = {
    Name = "private-subnet-2"
    "kubernetes.io/role/internal-elb" = "1"
  }
}

# Internet Gateway for public subnets
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  
  tags = {
    Name = "eks-igw"
  }
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat_1" {
  domain = "vpc"
  
  tags = {
    Name = "nat-gateway-eip-1"
  }
}

resource "aws_eip" "nat_2" {
  domain = "vpc"
  
  tags = {
    Name = "nat-gateway-eip-2"
  }
}

# NAT Gateways
resource "aws_nat_gateway" "nat_1" {
  allocation_id = aws_eip.nat_1.id
  subnet_id     = aws_subnet.public_1.id
  
  tags = {
    Name = "nat-gateway-1"
  }
}

resource "aws_nat_gateway" "nat_2" {
  allocation_id = aws_eip.nat_2.id
  subnet_id     = aws_subnet.public_2.id
  
  tags = {
    Name = "nat-gateway-2"
  }
}

# Route tables and associations
# ...