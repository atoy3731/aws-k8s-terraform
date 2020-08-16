resource "aws_security_group" "k8s_db_sg" {
  name        = "k8s-db-sg"
  description = "Allow traffic for K8S DB"
  vpc_id      = aws_vpc.k8s_vpc.id

  ingress {
    description = "Ingress Control Plane"
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "k8s-db-sg"
  }
}

resource "aws_db_subnet_group" "k8s_backend_db_subnets" {
  name       = "k8s-backend-db-subnets"
  subnet_ids = [aws_subnet.k8s_private_subnet_1.id, aws_subnet.k8s_private_subnet_2.id]

  tags = {
    Name = "K8S Backend DB Subnets"
  }
}

resource "aws_rds_cluster" "k8s_backend_db_cluster" {
  cluster_identifier      = "k8s-backend-db-cluster"
  engine                  = "aurora-postgresql"

  db_subnet_group_name = aws_db_subnet_group.k8s_backend_db_subnets.name

  database_name           = "k3sdb"
  master_username         = var.db_username
  master_password         = var.db_password
  backup_retention_period = 5
  preferred_backup_window = "07:00-09:00"

  final_snapshot_identifier = "k8s-db-cluster-backup"
  skip_final_snapshot       = true

  vpc_security_group_ids = [aws_security_group.k8s_db_sg.id]
}

resource "aws_rds_cluster_instance" "k8s_backend_db_instance" {
  count              = 1
  identifier         = "k8s-backend-db"
  cluster_identifier = aws_rds_cluster.k8s_backend_db_cluster.id
  instance_class     = "db.r5.large"
  engine             = aws_rds_cluster.k8s_backend_db_cluster.engine
}