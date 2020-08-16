data "aws_availability_zones" "available_azs" {
  state = "available"
}

#######
# VPC #
#######

resource "aws_vpc" "k8s_vpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "K8S VPC"
  }
}

###########
# SUBNETS #
###########

resource "aws_subnet" "k8s_private_subnet_1" {
  vpc_id     = aws_vpc.k8s_vpc.id
  availability_zone = data.aws_availability_zones.available_azs.names[0]
  cidr_block = var.private_subnet_1_cidr

  tags = {
    Name = "K8S Private Subnet 1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "KubernetesCluster" = var.cluster_name
    "kubernetes.io/role/internal-elb" = ""
  }
}

resource "aws_subnet" "k8s_private_subnet_2" {
  vpc_id     = aws_vpc.k8s_vpc.id
  availability_zone = data.aws_availability_zones.available_azs.names[1]
  cidr_block = var.private_subnet_2_cidr

  tags = {
    Name = "K8S Private Subnet 2"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "KubernetesCluster" = var.cluster_name
    "kubernetes.io/role/internal-elb" = ""
  }
}

resource "aws_subnet" "k8s_public_subnet_1" {
  vpc_id     = aws_vpc.k8s_vpc.id
  availability_zone = data.aws_availability_zones.available_azs.names[0]
  cidr_block = var.public_subnet_1_cidr

  tags = {
    Name = "K8S Public Subnet 1"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "KubernetesCluster" = var.cluster_name
    "kubernetes.io/role/elb" = ""
  }
}

resource "aws_subnet" "k8s_public_subnet_2" {
  vpc_id     = aws_vpc.k8s_vpc.id
  availability_zone = data.aws_availability_zones.available_azs.names[1]
  cidr_block = var.public_subnet_2_cidr

  tags = {
    Name = "K8S Public Subnet 2"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "KubernetesCluster" = var.cluster_name
    "kubernetes.io/role/elb" = ""
  }
}

############
# GATEWAYS #
############

resource "aws_internet_gateway" "k8s_igw" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "K8S IGW"
  }
}

resource "aws_eip" "k8s_nat_eip" {}

resource "aws_nat_gateway" "k8s_nat_gw" {
  allocation_id = aws_eip.k8s_nat_eip.id
  subnet_id = aws_subnet.k8s_public_subnet_1.id

  depends_on = [ aws_internet_gateway.k8s_igw ]
}

################
# ROUTE TABLES #
################

resource "aws_route_table" "k8s_public_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_igw.id
  }

  tags = {
    Name = "K8S Public Route Table"
  }
}

resource "aws_route_table_association" "k8s_public_rt_assoc_1" {
  subnet_id      = aws_subnet.k8s_public_subnet_1.id
  route_table_id = aws_route_table.k8s_public_rt.id
}

resource "aws_route_table_association" "k8s_public_rt_assoc_2" {
  subnet_id      = aws_subnet.k8s_public_subnet_2.id
  route_table_id = aws_route_table.k8s_public_rt.id
}

resource "aws_route_table" "k8s_private_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.k8s_nat_gw.id
  }

  tags = {
    Name = "K8S Private Route Table"
  }
}

resource "aws_route_table_association" "k8s_private_rt_assoc_1" {
  subnet_id      = aws_subnet.k8s_private_subnet_1.id
  route_table_id = aws_route_table.k8s_private_rt.id
}

resource "aws_route_table_association" "k8s_private_rt_assoc_2" {
  subnet_id      = aws_subnet.k8s_private_subnet_2.id
  route_table_id = aws_route_table.k8s_private_rt.id
}