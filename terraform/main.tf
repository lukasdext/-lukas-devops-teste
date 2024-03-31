provider "aws" {
  region = "us-east-1" # Defina a região desejada
}

resource "aws_ecrpublic_repository" "my_repo" {

  repository_name = "my-repo"

  catalog_data {
    about_text        = "About Text"
    architectures     = ["ARM"]
    description       = "Description"
    operating_systems = ["Linux"]
    usage_text        = "Usage Text"
  }

  tags = {
    env = "production"
  }
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24" 
  availability_zone = "us-east-1a"  
  map_public_ip_on_launch = true
}

resource "aws_security_group" "ecs_sg" {
  vpc_id      = aws_vpc.my_vpc.id
  name        = "ecs-sg"
  description = "Security group for ECS tasks"
  
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}





resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"
}

#######################################################

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": {
          "Service": "ecs-tasks.amazonaws.com"
        },
        "Action": "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "ecsPolicy" {
  name        = "ecsPolicy"
  description = "Policy for ECS task registration"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid       = "RegisterTaskDefinition",
        Effect    = "Allow",
        Action    = [
          "ecs:RegisterTaskDefinition"
        ],
        Resource  = "*"
      },
      {
        Sid       = "PassRolesInTaskDefinition",
        Effect    = "Allow",
        Action    = [
          "iam:PassRole"
        ],
        Resource  = [
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/my-task-role",
          "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/my-task-execution-role"
        ]
      },
      {
        Sid       = "DeployService",
        Effect    = "Allow",
        Action    = [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ],
        Resource  = [
          "arn:aws:ecs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:service/my-cluster/my-service"
        ]
      },
      {
        Sid       = "GetAuthorizationToken",
        Effect    = "Allow",
        Action    = [
          "ecr:GetAuthorizationToken"
        ],
        Resource  = "*"
      },
      {
        Sid       = "BatchCheckLayerAvailability",
        Effect    = "Allow",
        Action    = [
          "ecr:BatchCheckLayerAvailability"
        ],
        Resource  = "*"
      }
    ]
  })
}


resource "aws_iam_role_policy_attachment" "ecsPolicyAttachment" {
  role       = aws_iam_role.ecsTaskExecutionRole.name
  policy_arn = aws_iam_policy.ecsPolicy.arn
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

#######################################################

resource "aws_ecs_task_definition" "my_task" {
  family                   = "my-task"
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

  container_definitions = jsonencode([
    {
      "name": "teste-devops",
      "image": "node:latest",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 3000,
          "hostPort": 3000,
          "protocol": "tcp"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "ecs-logs",
          "awslogs-region": "us-east-1",
          "awslogs-stream-prefix": "ecs"
        }
      },
      "networkConfiguration": {
        "awsvpcConfiguration": {
          "assignPublicIp": "ENABLED"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "my_service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  
  
  network_configuration {
    subnets         = [aws_subnet.public_subnet.id]
    assign_public_ip = true
    security_groups = [aws_security_group.ecs_sg.id]
  }
}
