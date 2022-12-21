terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
variable "my_access_key" {
  description = "AWS Key"
}
variable "my_secret_key" {
  description = "AWS secret"
}
# Configure the AWS Provider
provider "aws" {
  region = "us-west-1"
  access_key = var.my_access_key
  secret_key = var.my_secret_key
}
# Create a Production VPC
resource "aws_vpc" "vpc-prod" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "prod-vpc"
  }
}
# Create Internet Gateway
resource "aws_internet_gateway" "prod-gateway" {
  vpc_id = aws_vpc.vpc-prod.id
  depends_on = [
    aws_vpc.vpc-prod
  ]
  tags = {
    Name = "prod-gateway"
  }
}
# Create a Subnet for Prod
resource "aws_subnet" "subnet-prod" {
  depends_on = [
    aws_vpc.vpc-prod
  ]
  vpc_id     = aws_vpc.vpc-prod.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "prod-subnet"
  }
}
# Create a Subnet for Dev
resource "aws_subnet" "subnet-dev" {
  vpc_id     = aws_vpc.vpc-prod.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-1c"
  tags = {
    Name = "dev-subnet"
  }
}
#Create Route Table
resource "aws_route_table" "prod-route-table" {
  vpc_id = aws_vpc.vpc-prod.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.prod-gateway.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.prod-gateway.id
  }

  tags = {
    Name = "prod-route"
  }
}
# Associate Route Table with Subnet or gateway id
resource "aws_route_table_association" "rt-prod-subnet" {
  subnet_id      = aws_subnet.subnet-prod.id
  route_table_id = aws_route_table.prod-route-table.id
}
#Create Security Group for Prod
resource "aws_security_group" "sg-prod" {
  name        = "prod-sg"
  description = "Allow SSH from Home IP & Allow outbound traffic to internet"
  vpc_id      = aws_vpc.vpc-prod.id
  
  ingress {
    description      = "SSH from home IP"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["50.39.170.42/32"]
  }

  egress {
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "sg-prod"
  }
}
# create an Ubuntu server
resource "aws_instance" "turbot-2" {
    ami = "ami-0a1a70369f0fce06a"
    instance_type = "t2.micro"
    availability_zone = "us-west-1a"
    key_name = "turbot-2"
    subnet_id = aws_subnet.subnet-prod.id
    vpc_security_group_ids = [aws_security_group.sg-prod.id]
    tags = { 
      Name = "turbot-ubuntu"
    }
}
