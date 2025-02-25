environment = "dev"
project_id  = ""
region      = ""

vpc_cidr = ""


db_password       = ""
db_instance_type  = "db.t4g.small"
db_name           = ""
db_user           = ""
db_port           = ""
db_engine         = ""
db_engine_version = ""


db_allocated_storage     = 
db_max_allocated_storage = 

authorized_ips = []


cluster_name = ""

tfstate_bucket = ""
aws_access_key = ""
aws_secret_key = ""
node_max_size  = 3
node_min_size  = 2
node_size      = "t2.medium"
eks_access_entries = [
  {
    name          = ""
    principal_arn = ""
  },
]

default_AWS_profile = ""

redis_cluster_id               = ""
redis_engine                   = ""
redis_parameter_group_family   = ""
create_redis_cluster           = true
create_redis_replication_group = false
