terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.42.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_ecr_repository" "my_repo" {
  name = "my-repo"
}

# Criação do VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Criação das sub-redes
resource "aws_subnet" "my_subnets" {
  count             = length(var.subnet_cidrs)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = "us-east-1${count.index + 1}"  # Ajustando as zonas de disponibilidade
}

# Criação do grupo de segurança
resource "aws_security_group" "ecs_security_group" {
  name        = "ecs-security-group"
  description = "Security group for ECS service"

  # Regras de entrada (ingress)
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Permitindo acesso de qualquer lugar
  }

  # Regras de saída (egress)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # Permitindo tráfego para qualquer lugar
  }
}

# Criação do cluster ECS
resource "aws_ecs_cluster" "my_cluster" {
  name = "my-cluster"
}

# Definição da tarefa ECS
resource "aws_ecs_task_definition" "my_task" {
  family                   = "my-task"
  network_mode             = "awsvpc"
  cpu                      = var.task_cpu
  memory                   = var.task_memory

  container_definitions = jsonencode([
    {
      "name"            : "my-container",
      "image"           : var.task_image,
      "cpu"             : var.task_cpu,
      "memory"          : var.task_memory,
      "portMappings"    : [
        {
          "containerPort": 80
        }
      ]
    }
  ])
}





# Criação do serviço ECS
resource "aws_ecs_service" "my_service" {
  name            = "my-service"
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets         = aws_subnet.my_subnets[*].id
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group.arn
    container_name   = "my-container"
    container_port   = 80
  }
}

# Recursos adicionais para o Application Load Balancer (ALB)
resource "aws_lb" "my_alb" {
  name               = "my-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.ecs_security_group.id]
  subnets            = aws_subnet.my_subnets[*].id
}

resource "aws_lb_listener" "my_alb_listener" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group.arn
  }
}

resource "aws_lb_target_group" "my_target_group" {
  name     = "my-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.my_vpc.id

  target_type = "ip"

  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
    matcher             = "200"
  }
}

resource "aws_lb_target_group_attachment" "my_target_group_attachment" {
  target_group_arn = aws_lb_target_group.my_target_group.arn
  target_id        = aws_ecs_service.my_service.id
  port             = 80
}
