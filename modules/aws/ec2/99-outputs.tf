output "aws_placement_group_partition_arn" {
  value = resource.aws_placement_group.partition.arn
}

output "aws_placement_group_partition_id" {
  value = resource.aws_placement_group.partition.id
}

output "aws_placement_group_partition_name" {
  value = resource.aws_placement_group.partition.name
}

output "private_key_rsa" {
  value     = trimspace(tls_private_key.rsa_4096.private_key_openssh)
  sensitive = true
}

output "public_key_rsa" {
  value     = trimspace(tls_private_key.rsa_4096.public_key_openssh)
  sensitive = true
}

output "private_key_ecdsa" {
  value     = trimspace(tls_private_key.ED25519.private_key_openssh)
  sensitive = true
}

output "public_key_ecdsa" {
  value     = trimspace(tls_private_key.ED25519.public_key_openssh)
  sensitive = true
}

output "ssh_key_name" {
  value       = aws_key_pair.key_rsa.key_name
  description = "SSH key name"
}

output "ssh_key_id" {
  value       = aws_key_pair.key_rsa.id
  description = "SSH key ID"
}
