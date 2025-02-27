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

authorized_ips = "[\"xxx.xxx.xxx.xxx/32\",\"xxx.xxx.xxx.xxx/32\"]" # this is a JSON string. you'll need to use this format here and in the GitHub Secrets and Variables



cluster_name = ""

tfstate_bucket = ""
aws_access_key = ""
aws_secret_key = ""
node_max_size  = 3
node_min_size  = 2
node_size      = "t2.medium"
eks_access_entries = "[{\"name\" : \"<YOUR-USER>\",\"principal_arn\" : \"arn:aws:iam::<YOUR-ACCOUNT-ID>:user/<YOUR-USER>\"},{\"name\" : \"<YOUR-USER>\",\"principal_arn\" : \"arn:aws:iam::<YOUR-ACCOUNT-ID>:<YOUR-USER>\"}]" # this is a JSON string. you'll need to use this format here and in the GitHub Secrets and Variables

default_AWS_profile = ""

redis_cluster_id               = ""
redis_engine                   = ""
redis_parameter_group_family   = ""
create_redis_cluster           = true
create_redis_replication_group = false
