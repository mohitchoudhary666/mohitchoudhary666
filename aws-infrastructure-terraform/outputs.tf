output "vpc_id" {
  description = "Created VPC ID."
  value       = aws_vpc.main.id
}
output "public_subnet_id" {
  description = "Created public subnet ID."
  value       = aws_subnet.public.id
}
output "instance_id" {
  description = "Instance ID for Session Manager."
  value       = aws_instance.server.id
}
output "ssm_start_session_command" {
  description = "Open a shell without inbound SSH."
  value       = "aws ssm start-session --target ${aws_instance.server.id} --region ${var.aws_region}"
}
