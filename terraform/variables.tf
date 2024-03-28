# Definição das variáveis
variable "aws_region" {
  description = "Região da AWS onde será criado o cluster ECS e as dependências"
  default     = "us-east-1"
}

variable "subnet_cidrs" {
  description = "CIDR das sub-redes onde as tarefas ECS serão executadas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}


# Variáveis para definição da tarefa ECS
variable "task_image" {
  description = "Imagem Docker a ser usada para a tarefa ECS"
  default     = "nginx:latest"
}

variable "task_cpu" {
  description = "Quantidade de CPU alocada para a tarefa ECS em unidades de CPU"
  default     = 256
}

variable "task_memory" {
  description = "Quantidade de memória alocada para a tarefa ECS em megabytes"
  default     = 512
}

variable "container_name" {
  type    = string
  description = "The name of the container in the containerDefinitions section of your task definition"
  # Valor padrão opcional, se necessário
  default = "my-container"
}
