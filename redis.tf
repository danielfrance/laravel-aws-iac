# AWS Elasticache does not natively support compute autoscaling. For higher availability we can use an elasticache cluster mode - https://registry.terraform.io/modules/terraform-aws-modules/elasticache/aws/latest#redis-cluster-mode


# TODO: use the `aws_elasticache_parameter_group` resource to create a parameter group for the redis cluster and apply it to the cluster. Remove the `create_parameter_group` and `parameter_group_family` from the module. AWS does not allow you to update the parameter group of an existing cluster. So we create one, apply it, and then update the cluster to use it rather than destroying the parameter group AND the cluster. This way we'll just destroy the parameter group and create a new one.


resource "aws_elasticache_parameter_group" "redis_queue_pg_v1" {
  name        = "${var.environment}-${var.redis_cluster_id}-parameter-group-v1"
  family      = "redis7"
  description = "Redis Parameter Group for Laravel Queue - Version 1"

  parameter {
    name  = "maxmemory-policy"
    value = "volatile-lru"
  }

  parameter {
    name  = "maxmemory-samples"
    value = "5"
  }
}

module "elasticache" {
  source = "terraform-aws-modules/elasticache/aws"

  cluster_id               = "${var.environment}-${var.project_id}-${var.redis_cluster_id}"
  create_cluster           = var.create_redis_cluster
  create_replication_group = var.create_redis_replication_group # set to true for scaling capabilities but change `create_cluster` to false. a cluster and replication group are different things. a cluster is a single node that is the primary and a replication group creates a multi-node cluster. you can not have both. 



  engine         = var.redis_engine
  engine_version = "7.1"
  node_type      = "cache.t4g.small"
  #   az_mode         = "cross-az" # for higher availability

  maintenance_window = "sun:05:00-sun:09:00"
  apply_immediately  = true

  # num_cache_nodes = 2 # for higher availability
  # automatic_failover_enabled = true # for higher availability

  # Security group
  vpc_id = module.vpc.vpc_id
  security_group_rules = {
    ingress_vpc = {
      # Default type is `ingress`
      # Default port is based on the default engine port
      description = "VPC traffic"
      cidr_ipv4   = module.vpc.vpc_cidr_block
    }
  }

  # Subnet Group
  subnet_ids = module.vpc.private_subnets

  # Parameter Group
  # create_parameter_group = true
  # parameter_group_family = var.redis_parameter_group_family
  parameters = [
    {
      name  = "timeout"
      value = 2000
    },
    {
      name  = "latency-tracking" #enables latency tracking to monitor slow redis operations
      value = "yes"
    }
  ]

  tags = {
    Terraform   = "true"
    Environment = "dev"
  }
}

#  +----------------------+
#                    |    EKS Worker Node   |
#                    |  (Your Laravel App)  |
#                    +----------------------+
#                              │
#        Only EKS Can Access   │  Allowed via Security Group
#                              ▼
#                    +----------------------+
#                    |   Redis ElastiCache   |
#                    |   (Port 6379 Open)    |
# +----------------------+

module "redis_security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 5.0"

  name        = "${var.environment}-redis-sg"
  description = "Security group for Redis ElastiCache"
  vpc_id      = module.vpc.vpc_id

  # Allow inbound traffic only from EKS worker nodes
  ingress_with_source_security_group_id = [
    {
      from_port                = 6379
      to_port                  = 6379
      protocol                 = "tcp"
      description              = "Allow EKS nodes to access Redis"
      source_security_group_id = module.eks.node_security_group_id
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
    Name        = "${var.environment}-redis-sg"
    Environment = var.environment
  }
}
