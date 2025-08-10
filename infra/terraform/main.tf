
provider "aws" {
  region = "us-east-1"
}

variable "existing_bucket_name" {
  default = "mydemobucket-2810"
}

#  ONE IAM ROLE for both Crawler & Job
resource "aws_iam_role" "glue_role" {
  name = "demo_glue_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# Attach required policies
resource "aws_iam_role_policy_attachment" "glue_service_role" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

# Glue Database
resource "aws_glue_catalog_database" "demo_db" {
  name = "demo_db"
}

# Glue Crawler (uses SAME role)
resource "aws_glue_crawler" "demo_crawler" {
  name          = "demo-crawler"
  role          = aws_iam_role.glue_role.arn
  database_name = aws_glue_catalog_database.demo_db.name

  s3_target {
    path = "s3://${var.existing_bucket_name}/data/"
  }
}

# Upload placeholder Glue Job script to S3
resource "aws_s3_object" "glue_job_script" {
  bucket = var.existing_bucket_name
  key    = "scripts/my_glue_job.py"
  source = "scripts/my_glue_job.py"
  etag   = filemd5("scripts/my_glue_job.py")
}

#  Glue ETL Job (uses SAME role)
resource "aws_glue_job" "demo_job" {
  name     = "demo-placeholder-job"
  role_arn = aws_iam_role.glue_role.arn

  command {
    name            = "glueetl"
    python_version  = "3"
    script_location = "s3://${var.existing_bucket_name}/scripts/my_glue_job.py"
  }

  default_arguments = {
    "--job-language" = "python"
    "--TempDir"      = "s3://${var.existing_bucket_name}/temp/"
  }

  glue_version      = "4.0"
  number_of_workers = 2
  worker_type       = "G.1X"
}

