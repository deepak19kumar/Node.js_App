# main.tf
provider "aws" {
  region = "ap-south-1"
}

resource "aws_key_pair" "ghactions" {
  key_name   = "ghactions-key"
  public_key = file("github-actions-ci.pub") # pre-generated public SSH key used by GitHub Actions
}

resource "aws_security_group" "allow_http_ssh" {
  name        = "allow_http_ssh"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "app" {
  ami           = "ami-0f918f7e67a3323f0"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ghactions.key_name
  vpc_security_group_ids = [aws_security_group.allow_http_ssh.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update
              sudo apt install -y nodejs npm git pm2
              # git clone https://github.com/<your-username>/<repo>.git /home/ubuntu/app
              # cd /home/ubuntu/app
              # npm install
              # pm2 start index.js --name app
              # pm2 startup
              # pm2 save
            EOF

  tags = { Name = "node-app-ec2" }
}

output "ec2_ip" {
  value = aws_instance.app.public_ip
}
