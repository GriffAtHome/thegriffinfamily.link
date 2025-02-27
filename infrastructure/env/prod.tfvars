aws_region = "us-east-1"
environment = "prod"

#VPC variables
vpc_cidr_block = "10.0.0.0/16"
public_subnet_1_cidr = "10.0.0.0/24"
public_subnet_2_cidr = "10.0.1.0/24"
private_subnet_1_cidr = "10.0.10.0/24"
private_subnet_2_cidr = "10.0.11.0/24"
availability_zone_1 = "us-east-1a"
availability_zone_2 = "us-east-1b"

#EKS variables
kubernetes_version = "1.31"
node_instance_types = ["t3.medium"] #EC2 instance types to use for EKS worker nodes"
node_disk_size = 20 #Disk size in GiB for worker nodesDisk size in GiB for worker nodes
node_desired_size = 2 #Desired number of worker nodes
node_max_size = 3 #Maximum number of worker nodes
node_min_size = 1 #Minimum number of worker nodes