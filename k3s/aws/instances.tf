data "template_file" "server_userdata" {
  template = "${file("${path.module}/templates/server_userdata.sh")}"

  vars = {
    cp_lb_host = aws_elb.k8s_cp_elb.dns_name
    datastore_endpoint = "postgres://${aws_rds_cluster.k8s_backend_db_cluster.master_username}:${aws_rds_cluster.k8s_backend_db_cluster.master_password}@${aws_rds_cluster.k8s_backend_db_cluster.endpoint}/${aws_rds_cluster.k8s_backend_db_cluster.database_name}"
    k3s_token = random_string.k3s_token.result
    s3_bucket = var.key_s3_bucket_name
    configure_aws_provider = var.configure_aws_provider
  }
}

data "template_file" "agent_userdata" {
  template = "${file("${path.module}/templates/agent_userdata.sh")}"

  vars = {
    cp_lb_host = aws_elb.k8s_cp_elb.dns_name
    k3s_token = random_string.k3s_token.result
    k3s_agent_count = var.k3s_agent_count
    configure_aws_provider = var.configure_aws_provider
  }
}

###########
# KEYPAIR #
###########

module "key_pair" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "${var.cluster_name}-keypair"
  public_key = var.public_ssh_key 
}

#############
# K3S TOKEN #
#############

resource "random_string" "k3s_token" {
  length = 20
  special = false
}

#################
# KEY S3 BUCKET #
#################

resource "aws_s3_bucket" "k8s_data_bucket" {
  bucket = var.key_s3_bucket_name
  acl    = "private"

  force_destroy = true

  tags = {
    Name = "k8s-data-bucket"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "KubernetesCluster"                 = var.cluster_name
  }
}

###########
# BASTION #
###########

resource "aws_security_group" "bastion_sg" {
  name        = "bastion-ssh"
  description = "Allow traffic for K8S Control Plane"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    description = "Ingress Bastion"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bastion-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "KubernetesCluster"                 = var.cluster_name
  }
}

resource "aws_instance" "bastion" {
  ami           = var.ami_id
  instance_type = "t2.micro"

  subnet_id = aws_subnet.k8s_public_subnet_1.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  associate_public_ip_address = true

  key_name = "${var.cluster_name}-keypair"

  tags = {
    Name = "k8s-bastion"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "KubernetesCluster"                 = var.cluster_name
  }
}

###########
# MASTERS #
###########

resource "aws_security_group" "k8s_cp_sg" {
  name        = "k8s-cp-sg"
  description = "Allow traffic for K8S Control Plane"
  vpc_id      = aws_vpc.k8s_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-cp-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "KubernetesCluster"                 = var.cluster_name
  }
}

resource "aws_security_group_rule" "k8s_cp_sg_self_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks = [aws_vpc.k8s_vpc.cidr_block]
  security_group_id = aws_security_group.k8s_cp_sg.id
}

resource "aws_security_group_rule" "k8s_cp_ingress" {
    description = "Ingress Control Plane"
    type        = "ingress"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
   security_group_id = aws_security_group.k8s_cp_sg.id
}

resource "aws_iam_policy" "k8s_master_iam_policy" {
  name        = "k8s-master-iam-policy"
  path        = "/"
  description = "K8S Master IAM Policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "s3:*"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:s3:::${var.key_s3_bucket_name}/*"
    }
  ]
}
EOF
}

resource "aws_iam_policy" "k8s_master_aws_iam_policy" {
  name        = "k8s-master-aws-iam-policy"
  path        = "/"
  description = "K8S Master AWS IAM Policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeLaunchConfigurations",
        "autoscaling:DescribeTags",
        "ec2:DescribeInstances",
        "ec2:DescribeRegions",
        "ec2:DescribeRouteTables",
        "ec2:DescribeSecurityGroups",
        "ec2:DescribeSubnets",
        "ec2:DescribeVolumes",
        "ec2:CreateSecurityGroup",
        "ec2:CreateTags",
        "ec2:CreateVolume",
        "ec2:ModifyInstanceAttribute",
        "ec2:ModifyVolume",
        "ec2:AttachVolume",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:DeleteSecurityGroup",
        "ec2:DeleteVolume",
        "ec2:DetachVolume",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:DescribeVpcs",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:AttachLoadBalancerToSubnets",
        "elasticloadbalancing:ApplySecurityGroupsToLoadBalancer",
        "elasticloadbalancing:CreateLoadBalancer",
        "elasticloadbalancing:CreateLoadBalancerPolicy",
        "elasticloadbalancing:CreateLoadBalancerListeners",
        "elasticloadbalancing:ConfigureHealthCheck",
        "elasticloadbalancing:DeleteLoadBalancer",
        "elasticloadbalancing:DeleteLoadBalancerListeners",
        "elasticloadbalancing:DescribeLoadBalancers",
        "elasticloadbalancing:DescribeLoadBalancerAttributes",
        "elasticloadbalancing:DetachLoadBalancerFromSubnets",
        "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
        "elasticloadbalancing:ModifyLoadBalancerAttributes",
        "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
        "elasticloadbalancing:SetLoadBalancerPoliciesForBackendServer",
        "elasticloadbalancing:AddTags",
        "elasticloadbalancing:CreateListener",
        "elasticloadbalancing:CreateTargetGroup",
        "elasticloadbalancing:DeleteListener",
        "elasticloadbalancing:DeleteTargetGroup",
        "elasticloadbalancing:DescribeListeners",
        "elasticloadbalancing:DescribeLoadBalancerPolicies",
        "elasticloadbalancing:DescribeTargetGroups",
        "elasticloadbalancing:DescribeTargetHealth",
        "elasticloadbalancing:ModifyListener",
        "elasticloadbalancing:ModifyTargetGroup",
        "elasticloadbalancing:RegisterTargets",
        "elasticloadbalancing:DeregisterTargets",
        "elasticloadbalancing:SetLoadBalancerPoliciesOfListener",
        "iam:CreateServiceLinkedRole",
        "kms:DescribeKey"
      ],
      "Effect": "Allow",
      "Resource": ["*"]
    }
  ]
}
EOF
}

resource "aws_iam_role" "k8s_master_iam_role" {
  name = "k8s_server_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name = "k8s_server_role"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "KubernetesCluster"                 = var.cluster_name
  }
}

resource "aws_iam_role_policy_attachment" "k8s_master_aws_iam_attach" {
  role       = aws_iam_role.k8s_master_iam_role.name
  policy_arn = aws_iam_policy.k8s_master_aws_iam_policy.arn
}

resource "aws_iam_role_policy_attachment" "k8s_master_iam_attach" {
  role       = aws_iam_role.k8s_master_iam_role.name
  policy_arn = aws_iam_policy.k8s_master_iam_policy.arn
}

resource "aws_iam_instance_profile" "k8s_master_iam_profile" {
  name = "k8s-master-iam-profile"
  role = aws_iam_role.k8s_master_iam_role.name
}

resource "aws_launch_template" "k8s_master_launch_template" {
  name = "k8s-master-launch-template"

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 20
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.k8s_master_iam_profile.name
  }

  image_id = var.ami_id
  instance_type = var.k3s_server_size

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [aws_security_group.k8s_cp_sg.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "k8s-master"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      "KubernetesCluster"                 = var.cluster_name

    }
  }

  key_name = "${var.cluster_name}-keypair" 
  user_data = base64encode(data.template_file.server_userdata.rendered)
}

resource "aws_autoscaling_group" "k8s_master_asg" {
  name                 = "k8s-master-asg"

  launch_template {
    id      = aws_launch_template.k8s_master_launch_template.id
    version = "$Latest"
  }

  min_size             = var.k3s_server_count
  max_size             = var.k3s_server_count
  desired_capacity = var.k3s_server_count

  vpc_zone_identifier = [aws_subnet.k8s_private_subnet_1.id, aws_subnet.k8s_private_subnet_2.id]

  lifecycle {
    create_before_destroy = true
  }

  tag {
    key = "kubernetes.io/cluster/${var.cluster_name}"
    value = "owned"
    propagate_at_launch = true
  }

  tag {
    key = "KubernetesCluster"
    value = var.cluster_name
    propagate_at_launch = true
  }
}

##########
# AGENTS #
##########

resource "aws_security_group" "k8s_agent_sg" {
  name        = "k8s-agent-sg"
  description = "Allow traffic for K8S Agent"
  vpc_id      = aws_vpc.k8s_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-agent-sg"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "KubernetesCluster"                 = var.cluster_name
  }
}

resource "aws_security_group_rule" "k8s_agent_sg_http_ingress" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s_agent_sg.id
}


resource "aws_security_group_rule" "k8s_agent_sg_https_ingress" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  security_group_id = aws_security_group.k8s_agent_sg.id
}

resource "aws_security_group_rule" "k8s_agent_sg_self_ingress" {
  type              = "ingress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks = [aws_vpc.k8s_vpc.cidr_block]
  security_group_id = aws_security_group.k8s_agent_sg.id
}

resource "aws_iam_role" "k8s_agent_iam_role" {
  name = "k8s_agent_role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF

  tags = {
    Name = "k8s_agent_role"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "KubernetesCluster"                 = var.cluster_name
  }
}

resource "aws_iam_policy" "k8s_agent_aws_iam_policy" {
  name        = "k8s-agent-aws-iam-policy"
  path        = "/"
  description = "K8S Master IAM AWS Policy"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances",
        "ec2:DescribeRegions",
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:GetRepositoryPolicy",
        "ecr:DescribeRepositories",
        "ecr:ListImages",
        "ecr:BatchGetImage"
      ],
      "Effect": "Allow",
      "Resource": ["*"]
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "k8s_agent_aws_iam_attach" {
  role       = aws_iam_role.k8s_agent_iam_role.name
  policy_arn = aws_iam_policy.k8s_agent_aws_iam_policy.arn
}

resource "aws_iam_instance_profile" "k8s_agent_iam_profile" {
  name = "k8s-agent-iam-profile"
  role = aws_iam_role.k8s_agent_iam_role.name
}

resource "aws_launch_template" "k8s_agent_launch_template" {
  name = "k8s-agent-launch-template"

  block_device_mappings {
    device_name = "/dev/sda1"

    ebs {
      volume_size = 50
    }
  }

  iam_instance_profile {
    name = aws_iam_instance_profile.k8s_agent_iam_profile.name
  }

  image_id = var.ami_id
  instance_type = var.k3s_server_size

  monitoring {
    enabled = true
  }

  vpc_security_group_ids = [aws_security_group.k8s_agent_sg.id]

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "k8s-agent"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
      "KubernetesCluster"                 = var.cluster_name
    }
  }

  key_name = "${var.cluster_name}-keypair" 
  user_data = base64encode(data.template_file.agent_userdata.rendered)
}

resource "aws_autoscaling_group" "k8s_agent_asg" {
  name                 = "k8s-agent-asg"

  launch_template {
    id      = aws_launch_template.k8s_agent_launch_template.id
    version = "$Latest"
  }

  min_size             = var.k3s_agent_count
  max_size             = var.k3s_agent_count
  desired_capacity = var.k3s_agent_count

  vpc_zone_identifier = [aws_subnet.k8s_private_subnet_1.id, aws_subnet.k8s_private_subnet_2.id]

  lifecycle {
    create_before_destroy = true
  }
}

#####################
# CONTROL PLANE ELB #
#####################

resource "aws_elb" "k8s_cp_elb" {
  name               = "k8s-cp-elb"

  subnets = [aws_subnet.k8s_public_subnet_1.id, aws_subnet.k8s_public_subnet_2.id]

  listener {
    instance_port     = 6443
    instance_protocol = "tcp"
    lb_port           = 6443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "TCP:6443"
    interval            = 30
  }

  cross_zone_load_balancing   = true
  idle_timeout                = 400
  connection_draining         = true
  connection_draining_timeout = 400

  tags = {
    Name = "k8s-cp-elb"
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    "KubernetesCluster"                 = var.cluster_name
  }

  security_groups = [aws_security_group.k8s_cp_sg.id]
}

resource "aws_autoscaling_attachment" "k8s_cp_lb_attachment" {
  autoscaling_group_name = aws_autoscaling_group.k8s_master_asg.id
  elb                    = aws_elb.k8s_cp_elb.id
}
