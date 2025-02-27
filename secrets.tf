resource "aws_secretsmanager_secret" "db_secret" {
  name                    = "${var.environment}-laravel-rds-db-secret"
  description             = "Secret for RDS DB"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_secret_version" {
  secret_id = aws_secretsmanager_secret.db_secret.id
  secret_string = jsonencode({
    username = var.db_user
    password = var.db_password
  })
}

resource "aws_secretsmanager_secret" "redis_secret" {
  name                    = "${var.environment}-laravel-redis-secret"
  description             = "Secret for Laravel Redis"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "redis_secret_version" {
  secret_id = aws_secretsmanager_secret.redis_secret.id
  secret_string = jsonencode({
    REDIS_HOST     = module.elasticache.cluster_address
    REDIS_PORT     = 6379
    REDIS_PASSWORD = "" # We are using a non-password protected Redis for now
  })
}
