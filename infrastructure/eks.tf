# IAM Role for EKS Cluster
resource "aws_iam_role" "eks_cluster" {
  name = "${local.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach required policies to cluster role
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks_cluster.name
}

# IAM Role for EKS Node Group
resource "aws_iam_role" "eks_node_group" {
  name = "${local.project_name}-eks-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# Attach required policies to node role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.eks_node_group.name
}

resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.eks_node_group.name
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "${local.project_name}-${local.environment}"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids      = [aws_security_group.eks_cluster.id]
  }

  # Enable EKS control plane logging
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = local.common_tags
}

# Resource for proper OIDC management
resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
  url             = aws_eks_cluster.main.identity[0].oidc[0].issuer
}

# EKS Node Group
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${local.project_name}-node-group"
  node_role_arn   = aws_iam_role.eks_node_group.arn
  subnet_ids      = [aws_subnet.private_1.id, aws_subnet.private_2.id]
  
  # Direct configuration - Could use launch template here, but went for direct configuration for simplicity
  instance_types = var.node_instance_types
  disk_size      = var.node_disk_size
  
  # Remove the launch_template block completely
  
  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  # Auto-scaling configuration
  update_config {
    max_unavailable = 1
  }

  # Use the latest EKS-optimized Amazon Linux 2 AMI
  ami_type = "AL2_x86_64"

  # Ensure VPC CNI policy is attached
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy,
    aws_eks_cluster.main
  ]
  
  # Add required tags
  tags = merge(
    local.common_tags,
    {
      "kubernetes.io/cluster/${local.project_name}-${local.environment}" = "owned"
      "k8s.io/cluster-autoscaler/enabled" = "true"
      "k8s.io/cluster-autoscaler/${local.project_name}-${local.environment}" = "owned"
    }
  )
}

# Security group for EKS Cluster
resource "aws_security_group" "eks_cluster" {
  name        = "${local.project_name}-eks-cluster-sg"
  description = "Security group for EKS cluster control plane"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-eks-cluster-sg"
    }
  )
}

# Allow worker nodes to communicate with the cluster
resource "aws_security_group_rule" "eks_cluster_ingress_node_https" {
  description              = "Allow worker nodes to communicate with the cluster API Server"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_cluster.id
  source_security_group_id = aws_security_group.eks_nodes.id
  to_port                  = 443
  type                     = "ingress"
}

# Security group for worker nodes
resource "aws_security_group" "eks_nodes" {
  name        = "${local.project_name}-eks-node-sg"
  description = "Security group for EKS worker nodes"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow nodes to communicate with each other
  ingress {
    description = "Allow nodes to communicate with each other"
    from_port   = 0
    to_port     = 0 #Allow all
    protocol    = "-1"
    self        = true
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-eks-node-sg"
      "kubernetes.io/cluster/${local.project_name}-${local.environment}" = "owned"
    }
  )
}

# Allow worker nodes to communicate with the cluster API Server
resource "aws_security_group_rule" "eks_nodes_ingress_cluster" {
  description              = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  from_port                = 1025
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
  to_port                  = 65535
  type                     = "ingress"
}

# Allow control plane to access node ports 10250
resource "aws_security_group_rule" "eks_nodes_ingress_control_plane" {
  description              = "Allow control plane to access kubelet API"
  from_port                = 10250
  protocol                 = "tcp"
  security_group_id        = aws_security_group.eks_nodes.id
  source_security_group_id = aws_security_group.eks_cluster.id
  to_port                  = 10250
  type                     = "ingress"
}

# Create a placeholder security group for the ALB ingress
resource "aws_security_group" "alb_ingress" {
  name        = "${local.project_name}-alb-ingress"
  description = "Security group for ALB ingress traffic"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    local.common_tags,
    {
      Name = "${local.project_name}-alb-ingress"
    }
  )
}

# Allow traffic from this security group to the Flask app
resource "aws_security_group_rule" "allow_alb_to_flask" {
  type                     = "ingress"
  from_port                = 8000
  to_port                  = 8000
  protocol                 = "tcp"
  security_group_id        = aws_eks_cluster.main.vpc_config[0].cluster_security_group_id
  source_security_group_id = aws_security_group.alb_ingress.id
  description              = "Allow traffic from ALB to Flask app"
}
