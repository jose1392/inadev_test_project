# Configure AWS Provider
provider "aws" {
  region = "us-east-2"
}

# VPC Configuration 
resource "aws_vpc" "eks_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Internet Gateway Configuration 
resource "aws_internet_gateway" "eks_gateway" {
  vpc_id = aws_vpc.eks_vpc.id
}

# Subnet Configuration 
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.eks_vpc.id
  cidr_block         = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  map_public_ip_on_launch = true
}

# Route Table Configuration 
resource "aws_route_table" "eks_route_table" {
  vpc_id = aws_vpc.eks_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.eks_gateway.id
  }
}

# Route Table Association with Subnet
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.eks_route_table.id
}

# EKS Cluster with Public Access 
resource "aws_eks_cluster" "eks_cluster" {
  name          = "my-eks-cluster"
  role_arn      = "arn:aws:iam::ACCOUNT_ID:role/eks-admin-role" # Replace with your IAM role ARN
  vpc_config {
    security_group_ids = ["${aws_security_group.eks_sg.id}"]
    subnet_ids        = [aws_subnet.public_subnet.id]
  }
 
}

# Security Group for Nodes 
resource "aws_security_group" "eks_sg" {
  name = "eks-cluster-sg"
  vpc_id = aws_vpc.eks_vpc.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Outputs
output "cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "kubeconfig" {
  value = aws_eks_cluster.eks_cluster.kubeconfig
}
