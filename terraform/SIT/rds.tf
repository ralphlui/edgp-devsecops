# Create Security Group for RDS
# --- 1. Security Group for RDS ---
resource "aws_security_group" "rds_sg" {
  name        = "rds-control-server-security_group"
  description = "Allow database traffic"
  vpc_id      = aws_vpc.vpc.id

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
  }

  ingress {
    cidr_blocks = ["10.0.0.10/32"]
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
  }

  tags = {
    Name = "rds-edgp-mysql-security-group"
  }

  lifecycle {
    ignore_changes = all
  }
}

resource "aws_security_group" "lambda_sg" {
  name        = "lambda-to-rds-sg"
  description = "Allow Lambda to connect to RDS MySQL"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # All traffic outbound allowed
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group_rule" "allow_lambda_to_rds" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  security_group_id        = aws_security_group.rds_sg.id
  source_security_group_id = aws_security_group.lambda_sg.id
  description              = "Allow Lambda SG to connect to RDS"
}

# --- 2. RDS Subnet Group ---
resource "aws_db_subnet_group" "db_control_server_subnet_group" {
  name        = "rds-ec2-db-control-server-subnet-group"
  description = "SIT RDS DB Subnet Group"
  subnet_ids  = [element(aws_subnet.private_subnet_a[*].id, 2), element(aws_subnet.private_subnet_b[*].id, 2)]

  tags = {
    Name = "rds-edgp-ec2-db-control-server-subnet-group"
  }
}

# Create a secret in AWS Secrets Manager
# --- 3. Secrets Manager for RDS Credentials ---
resource "aws_secretsmanager_secret" "rds_credentials" {
  name = "rds-credentials-edgp-sit"
  description = "Credentials for RDS MySQL instance (edgp-sit)"
}

resource "aws_secretsmanager_secret_version" "rds_credentials" {
  secret_id = aws_secretsmanager_secret.rds_credentials.id
  secret_string = jsonencode({
    username = "admin"
    password = "RDS_12345"  # Initial password (will be rotated)
    engine   = "mysql"
    host     = aws_db_instance.control_server_rds.address
    port     = "3306"
    #dbname   = "edgp-sit"
  })
}

# Create RDS Instance
# --- 4. RDS MySQL Instance (Free Tier) ---
resource "aws_db_instance" "control_server_rds" {
  identifier           = "edgp-sit"
  allocated_storage    = 20 
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0.40"
  instance_class       = "db.t3.micro"
  #username             = jsondecode(aws_secretsmanager_secret_version.rds_credentials.secret_string)["username"]
  #password             = jsondecode(aws_secretsmanager_secret_version.rds_credentials.secret_string)["password"]
  username             = "admin"
  password             = "RDS_12345"
  db_subnet_group_name = aws_db_subnet_group.db_control_server_subnet_group.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  skip_final_snapshot  = true
  multi_az             = false
  publicly_accessible  = false
  tags = {
    Name = "edgp-sit-rds"
  }
}

# --- 5. IAM Role for Rotation ---
resource "aws_iam_role" "rds_rotation_lambda_role" {
  name = "rds-rotation-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy" "rds_rotation_lambda_rds_policy" {
  name = "rds-rotation-lambda-rds-access"
  role = aws_iam_role.rds_rotation_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "rds:DescribeDBInstances",
          "rds:ModifyDBInstance"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy" "lambda_vpc_permissions" {
  name = "lambda-vpc-permissions"
  role = aws_iam_role.rds_rotation_lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "secrets_manager_policy" {
  role       = aws_iam_role.rds_rotation_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/SecretsManagerReadWrite"
}

resource "aws_iam_role_policy_attachment" "vpc_execution_policy" {
  role       = aws_iam_role.rds_rotation_lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}


# --- 6. Rotation Lambda (Pre-Built by AWS) ---
resource "aws_lambda_function" "rds_rotation_lambda" {
  filename      = "SecretsManagerRDSMySQLRotationSingleUser.zip"
  function_name = "rds-password-rotator"
  role          = aws_iam_role.rds_rotation_lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"
  timeout       = 30

  environment {
    variables = {
      SECRETS_MANAGER_ENDPOINT = "https://secretsmanager.${var.aws_region}.amazonaws.com"
    }
  }

  vpc_config {
    subnet_ids         = [element(aws_subnet.private_subnet_a[*].id, 2), element(aws_subnet.private_subnet_b[*].id, 2)]
    security_group_ids = [aws_security_group.lambda_sg.id]
  }
}

# --- 7. Grant Secrets Manager permission to invoke Lambda function ---
resource "aws_lambda_permission" "allow_secretsmanager" {
  statement_id  = "AllowSecretsManagerInvocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.rds_rotation_lambda.function_name
  principal     = "secretsmanager.amazonaws.com"
  source_arn    = aws_secretsmanager_secret.rds_credentials.arn
}


# --- 8. Enable Automatic Rotation ---
resource "aws_secretsmanager_secret_rotation" "rds_rotation" {
  secret_id           = aws_secretsmanager_secret.rds_credentials.id
  rotation_lambda_arn = aws_lambda_function.rds_rotation_lambda.arn
  rotation_rules {
    automatically_after_days = 14
  }
}

# --- Outputs ---
output "rds_endpoint" {
  value = aws_db_instance.control_server_rds.endpoint
}

output "secret_arn" {
  value = aws_secretsmanager_secret.rds_credentials.arn
}
