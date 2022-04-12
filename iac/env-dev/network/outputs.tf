
# Outputs

output "vpc-main-id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public_subnets.*.id
}

output "private_subnet_ids" {
  value = aws_subnet.private_subnets.*.id
}

#output "key_name" {
#  value = "${aws_key_pair.ssh_key_281.key_name}"
#}
