provider "aws" {
  region = "us-east-1" # Defina a região desejada
}

resource "aws_ecr_repository" "my_repo" {
  name = "my-repo"
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
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"
}
####################################################################################################

resource "aws_iam_role" "task_execution_role" {
  name               = "ecs-task-execution-role"
  assume_role_policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
})
}

resource "aws_iam_policy" "ecs_policy" {
  name        = "ecs-policy"
  description = "Policy for ECS task registration"
  
  policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "RegisterTaskDefinition",
        "Effect": "Allow",
        "Action": [
          "ecs:RegisterTaskDefinition"
        ],
        "Resource": "*"
      },
      {
        "Sid": "PassRolesInTaskDefinition",
        "Effect": "Allow",
        "Action": [
          "iam:PassRole"
        ],
        "Resource": "*"
      },
      {
        "Sid": "DeployService",
        "Effect": "Allow",
        "Action": [
          "ecs:UpdateService",
          "ecs:DescribeServices"
        ],
        "Resource": "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_attachment" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.ecs_policy.arn
}

resource "aws_ecs_task_definition" "my_task" {
  family                   = "my-task"
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  
  execution_role_arn       = aws_iam_role.task_execution_role.arn

  container_definitions = jsonencode([
    {
      "name": "my-container",
      "image": "your-docker-image-url",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80,
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
