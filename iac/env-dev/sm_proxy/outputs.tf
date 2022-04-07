
output "sqs_url" {
  value = aws_sqs_queue.sm_trigger_queue.id
}
