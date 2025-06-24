resource "aws_instance" "sit_instance" {
  ami                    = var.ami_id
  instance_type          = "t3.medium"
  key_name               = "EDGP-SIT-keypair"
  subnet_id              = element(aws_subnet.public_subnet[*].id, 0)
  security_groups        = [aws_security_group.control-server.id]
  associate_public_ip_address = true

  user_data = file("install_jenkins_docker_minikube.sh")

  tags = {
    Name = "SIT-Server"
  }

  root_block_device {
    volume_size = var.disk_size
    volume_type = "gp3"
  }

  lifecycle {
    ignore_changes = all
  }
}

output "public_ip" {
  value = aws_instance.sit_instance.public_ip
}
