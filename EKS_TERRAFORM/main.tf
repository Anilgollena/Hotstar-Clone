# Assume Role Policy for EKS Cluster
data "aws_iam_policy_document" "assume_role" {
  statement {
    effect    = "Allow"
    actions   = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

# IAM Role for EKS Cluster
resource "aws_iam_role" "example" {
  name               = "eks-cluster-cloud"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Attach Policy to EKS Cluster Role
resource "aws_iam_role_policy_attachment" "example-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.example.name
}

# Get VPC and Subnets Data
data "aws_vpc" "default" {
  default = true
}

# Get Public Subnets Data for Cluster
data "aws_subnets" "public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "aws_eks_cluster" "example" {
  name     = "EKS_CLOUD"
  role_arn = aws_iam_role.example.arn

  vpc_config {
    subnet_ids = data.aws_subnets.public.ids  # Ensure subnets are in supported AZs
  }
}



# IAM Role for EKS Node Group
resource "aws_iam_role" "example1" {
  name               = "eks-node-group-cloud"
  assume_role_policy = jsonencode({
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
    Version = "2012-10-17"
  })
}

# Attach Policies to Node Group Role
resource "aws_iam_role_policy_attachment" "example-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.example1.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.example1.name
}

resource "aws_iam_role_policy_attachment" "example-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.example1.name
}

# EKS Node Group Configuration
resource "aws_eks_node_group" "example" {
  cluster_name    = aws_eks_cluster.example.name
  node_group_name = "Node-cloud"
  node_role_arn   = aws_iam_role.example1.arn
  subnet_ids      = data.aws_subnets.public.ids  # Using public subnet IDs from the data source

  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }

  instance_types = ["t2.medium"]

  # Ensure that IAM Role permissions are created before node group
  depends_on = [
    aws_iam_role_policy_attachment.example-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.example-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.example-AmazonEC2ContainerRegistryReadOnly,
  ]
}
