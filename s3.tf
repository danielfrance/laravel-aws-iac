module "rds_logs_s3" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket        = "${var.environment}-${var.logs_bucket}"
  force_destroy = true

  acl = "private"

  control_object_ownership = true
  object_ownership         = "BucketOwnerPreferred"

  versioning = {
    enabled = true
  }


  attach_policy = true
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "AllowCloudWatchLogsAccess",
        Effect = "Allow",
        Principal = {
          Service = "logs.amazonaws.com"
        },
        Action   = "s3:PutObject",
        Resource = "${module.rds_logs_s3.s3_bucket_arn}/*"
      },
      {
        Sid    = "AllowEKSUsersAccess",
        Effect = "Allow",
        Principal = {
          AWS = local.eks_access_entries[0].principal_arn
        },
        Action   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"],
        Resource = ["${module.rds_logs_s3.s3_bucket_arn}", "${module.rds_logs_s3.s3_bucket_arn}/*"]
      }
    ]
  })


  lifecycle_rule = [
    {
      id      = "log"
      enabled = true
      noncurrent_version_expiration = {
        days = 10
      }
      expiration = {
        days = 10
      }
    }
  ]



  tags = {
    Name        = "${var.environment}-${var.logs_bucket}"
    Environment = var.environment
  }

}
