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

# Criação do VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Criação das sub-redes
resource "aws_subnet" "my_subnets" {
  count             = length(var.subnet_cidrs)
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.subnet_cidrs[count.index]
  availability_zone = "us-east-1a"  # Especificando uma AZ para cada sub-rede (pode ser ajustado conforme necessário)
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
  name = "my-cluster"  # Nome do cluster ECS
}

# Definição da tarefa ECS
resource "aws_ecs_task_definition" "my_task" {
  family                   = "my-task"
  network_mode             = "awsvpc"  # Defina o modo de rede como "awsvpc" para Fargate
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
  name            = "my-service"  # Nome do serviço ECS
  cluster         = aws_ecs_cluster.my_cluster.id
  task_definition = aws_ecs_task_definition.my_task.arn
  desired_count   = 1  # Número de tarefas a serem executadas
  launch_type     = "FARGATE"  # Tipo de lançamento (FARGATE ou EC2)

  network_configuration {
    subnets         = aws_subnet.my_subnets[*].id  # IDs das sub-redes onde as tarefas serão executadas
    assign_public_ip = true  # Atribuir IP público às tarefas (apenas para FARGATE)
  }
}

resource "aws_ecr_repository" "my_repo" {
  name = "my-repo"  # Nome do repositório
}