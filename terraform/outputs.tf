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
  description = "Nome do serviço ECS criado"
  value       = aws_ecs_service.my_service.name
}
