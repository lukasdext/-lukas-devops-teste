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

resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "my_task" {
  family                   = "my-task"
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  
  execution_role_arn       = aws_iam_role.ecsTaskExecutionRole.arn

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
