locals {
  filename_rsa_prv_key     = "./keys/${var.ssh_key_name}_rsa_private.key"
  filename_rsa_pub_key     = "./keys/${var.ssh_key_name}_rsa_public.key"
  filename_ed25519_prv_key = "./keys/${var.ssh_key_name}_dsa_private.key"
  filename_ed25519_pub_key = "./keys/${var.ssh_key_name}_dsa_public.key"
}

resource "tls_private_key" "ED25519" {
  algorithm   = "ED25519"
  ecdsa_curve = "P384"
}

resource "tls_private_key" "rsa_4096" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key_openssh" {
  content    = tls_private_key.rsa_4096.public_key_openssh
  filename   = local.filename_rsa_prv_key
  depends_on = [tls_private_key.rsa_4096]
  provisioner "local-exec" {
    command = "mkdir -p ./keys && find ./keys -type f -exec chmod 0600 {} \\;"
  }
}

resource "local_file" "public_key_openssh" {
  content    = tls_private_key.rsa_4096.private_key_openssh
  filename   = local.filename_rsa_pub_key
  depends_on = [tls_private_key.rsa_4096, local_file.private_key_openssh]
  provisioner "local-exec" {
    command = "find ./keys -type f -exec chmod 0600 {} \\;"
  }
}

resource "local_file" "private_key_ecdsa" {
  content    = tls_private_key.ED25519.private_key_openssh
  filename   = local.filename_ed25519_prv_key
  depends_on = [tls_private_key.ED25519, local_file.private_key_openssh]
  provisioner "local-exec" {
    command = "find ./keys -type f -exec chmod 0600 {} \\;"
  }
}

resource "local_file" "public_key_ecdsa" {
  content    = tls_private_key.ED25519.public_key_openssh
  filename   = local.filename_ed25519_pub_key
  depends_on = [tls_private_key.ED25519, local_file.private_key_openssh]
  provisioner "local-exec" {
    command = "find ./keys -type f -exec chmod 0600 {} \\;"
  }
}

resource "aws_key_pair" "key_rsa" {
  key_name   = var.ssh_key_name
  public_key = tls_private_key.ED25519.public_key_openssh
  tags       = var.tags
}
