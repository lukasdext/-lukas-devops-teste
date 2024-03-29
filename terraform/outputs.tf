# Saídas
output "cluster_id" {
  description = "ID do cluster ECS criado"
  value       = aws_ecs_cluster.my_cluster.id
}

output "task_definition_arn" {
  description = "ARN da definição de tarefa ECS criada"
  value       = aws_ecs_task_definition.my_task.arn
}

output "service_name" {
  value = aws_ecs_service.my_service.name
}

# Armazenar a ARN da definição de tarefa ECS em uma variável de saída
output "ecs_task_definition_arn" {
  value = aws_ecs_task_definition.my_task.arn

}

output "aws_account_id" {
  value = data.aws_caller_identity.current.account_id
}

output "ecsTaskExecutionRole_arn" {
  value = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/ecsTaskExecutionRole"
}