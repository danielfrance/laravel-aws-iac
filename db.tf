# FYI: RDS does NOT auto-scale CPU & memory.  You can increase the allocated storage and the instance type to scale but it requires a manual process. it also requires a restart of the instance. Read operations may still work but write operations will fail. If multi_az is enabled, the standby replica gets promoted to primary and writes continue with minimal downtime... but that number is not 0.  this is a matter of your risk tolerance.  for 0 write downtime, you need to use aurora. Your app should have a way to retry failed writes.
# TODO: add read replica configuration
# TODO: create aurora example for auto-scaling
module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier                     = replace("${var.environment}-${var.db_name}", "_", "-") # Fix invalid characters
  instance_use_identifier_prefix = true

  # or just set a variable enable_deletion_protection
  deletion_protection = var.environment == "production" ? true : false

  # All available versions: https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/CHAP_PostgreSQL.html#PostgreSQL.Concepts

  engine               = var.db_engine
  engine_version       = var.db_engine_version
  family               = "postgres16" # DB parameter group
  major_engine_version = "16"         # DB option group
  instance_class       = var.db_instance_type

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = var.db_max_allocated_storage

  # NOTE: Do NOT use 'user' as the value for 'username' as it throws:
  # "Error creating DB Instance: InvalidParameterValue: MasterUsername
  # user cannot be used as it is a reserved word used by the engine"
  db_name  = var.db_name
  username = var.db_user
  password = random_password.db_password.result
  port     = var.db_port

  publicly_accessible = false
  multi_az            = false

  db_subnet_group_name   = aws_db_subnet_group.rds_subnet_group.name
  vpc_security_group_ids = [module.rds_security_group.security_group_id]

  # Backups & Monitoring
  backup_retention_period               = 7 # Keep backups for 7 days
  skip_final_snapshot                   = false
  performance_insights_enabled          = true
  performance_insights_retention_period = 7

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
  create_cloudwatch_log_group     = true

  cloudwatch_log_group_skip_destroy = true

  tags = {
    Name        = "${var.environment}-rds"
    Environment = var.environment
  }

  depends_on = [module.vpc, module.rds_security_group, aws_db_subnet_group.rds_subnet_group]

}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.environment}-rds-subnet-group"
  subnet_ids = module.vpc.private_subnets

  tags = {
    Name        = "${var.environment}-rds-subnet-group"
    Environment = var.environment
  }
}

module "rds_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.environment}-rds-sg"
  description = "Security group for RDS PostgreSQL"
  vpc_id      = module.vpc.vpc_id

  # Allow inbound traffic from EKS worker nodes
  ingress_with_source_security_group_id = [
    {
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      description              = "Allow EKS nodes to access RDS"
      source_security_group_id = module.eks.node_security_group_id
    }
  ]

  # Allow external access from whitelisted IPs
  ingress_with_cidr_blocks = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "Allow access from authorized external users"
      cidr_blocks = join(",", var.authorized_ips)
    }
  ]

  # Allow all outbound traffic (default)
  egress_with_cidr_blocks = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      description = "Allow all outbound traffic"
      cidr_blocks = "0.0.0.0/0"
    }
  ]

  tags = {
    Name        = "${var.environment}-rds-sg"
    Environment = var.environment
  }
}
