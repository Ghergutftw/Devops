resource "aws_instance" "web" {
  ami             = var.amis[var.region]
  instance_type   = "t3.micro"
  key_name        = aws_key_pair.key_pair_tf.key_name
  security_groups = [aws_security_group.security_group_tf.name]
  #   vpc_security_group_ids = [aws_security_group.security_group_tf.id]
  availability_zone = var.zone

  tags = {
    Name    = "DoverOps-Instance"
    Project = "Exercise2"
  }

  provisioner "file" {
    source      = "web.sh"
    destination = "/tmp/web.sh"
  }

  connection {
    type        = "ssh"
    user        = var.webuser
    private_key = file("key_pair")
    host        = self.public_ip

  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/web.sh",
      "sudo /tmp/web.sh"
    ]
  }

}

resource "aws_ec2_instance_state" "web_state" {
  instance_id = aws_instance.web.id
  state       = "running"
}

output "ip_address" {
  value = aws_instance.web.public_ip
}