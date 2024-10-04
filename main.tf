# Generate a new private key using the TLS provider
resource "tls_private_key" "example" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

# Upload the public key to AWS as a key pair
resource "aws_key_pair" "my_key" {
  key_name   = "${local.env_name}-mahesh-drupal-key" # Name of the key pair in AWS
  public_key = tls_private_key.example.public_key_openssh
}

# Save the private key to a local file
resource "local_file" "private_key" {
  filename        = "${path.module}/drupal_private_key.pem"
  content         = tls_private_key.example.private_key_pem
  file_permission = "0600" # Ensure correct permissions
}

resource "aws_instance" "rds-ec2" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.my_key.key_name
#   subnet_id     = aws_subnet.public_subnet_2.id
#   vpc_security_group_ids = [
#     aws_security_group.ec2_rds_sg.id
#   ]

  tags = {
    Name = "${local.env_name}-rds-instance"
  }
}