# Create a VPC
resource "aws_vpc" "example" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_vpc" "development-vpc" {
  cidr_block = "10.20.0.0/16"
}

resource "aws_subnet" "dev-aws_subnet-1" {
  vpc_id            = aws_vpc.development-vpc.id
  cidr_block        = "10.20.1.0/24"
  availability_zone = "us-east-1a"
}

# data "aws_vpc" "existing_vpc" {

# }

variable "vpc_cidr_blocks" {}
variable "subnet_cidr_block" {}
variable "avail_zone" {}
variable "env_prefix" {}
variable "instance_type" {}
variable "public_key_location" {}

resource "aws_vpc" "myapp-vpc" {
  cidr_block = var.vpc_cidr_blocks
  tags = {
    Name : "{var.env_prefix}-vpc"
  }
}
resource "aws_subnet" "myapp-subnet-1" {
  vpc_id            = aws_vpc.myapp-vpc.id
  cidr_block        = var.subnet_cidr_block
  availability_zone = var.avail_zone
  tags = {
    Name : "{var.env_prefix}-subnet-1"
  }
}
#Terraform is smart enough to know what order to create resources
# resource "aws_route_table" "myapp-route-table" {
#   vpc_id = aws_vpc.myapp-vpc.id
#   route {
#     cidr_block = "0.0.0.0/0"
#     gateway_id = aws_internet_gateway.myapp-igw.id
#   }
# }

resource "aws_internet_gateway" "myapp-igw" {
  vpc_id = aws_vpc.myapp-vpc.id
}


# resource "aws_route_table_association" "a-rtb-subnet" {
#   subnet_id      = aws_subnet.myapp-subnet-1.id
#   route_table_id = aws_route_table.myapp-route-table.id
# }

resource "aws_default_route_table" "main-rtb" {
  default_route_table_id = aws_vpc.myapp-vpc.default_route_table_id
}

resource "aws_security_group" "myapp-sg" {
  name   = "myapp-sg"
  vpc_id = aws_vpc.myapp-vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }
}

data "aws_ami" "latest-amazon-linux-image" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*x86_64-gp2"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
# output "aws_ami_id" {
#   value = data.aws_ami.latest-amazon-linux-image
# }
# resource "aws_key_pair" "ssh-key" {
#   key_name   = "server-key"
#   public_key = file(var.public_key_location)
# }

resource "aws_instance" "myapp-server" {
  ami           = data.aws_ami.latest-amazon-linux-image.id
  instance_type = var.instance_type

  subnet_id              = aws_subnet.myapp-subnet-1.id
  vpc_security_group_ids = [aws_security_group.myapp-sg.id]
  availability_zone      = var.avail_zone

  associate_public_ip_address = true
  # key_name                    = "server-key-pair"
  user_data = file("entry-script.sh")
  # user_data                   = <<EOF
  #               #!/bin/bash
  #               sudo yum update -y && sudo yum install -y docker
  #               sudo systemctrl start docker 
  #               sudo usermod -aG docker ec2-user
  #               docker run -p 8080:80 nginx
  #           EOF
  user_data_replace_on_change = true

  connection {
    type = "ssh"
    host = self.public_ip
    user = "ec2-user"
    # private_key = file(var.private_key_location)
  }

  #Provisioners are not recommended
  provisioner "file" {
    source      = "entry-script.sh"
    destination = "/home/ec2-user/entry-script-on-ec2.sh"
  }

  provisioner "remote-exec" {
    inline = ["/home/ec2-user/entry-script.sh"]
  }

  provisioner "local-exec" {
    command = "echo ${self.public_ip} > output.txt"
  }
}



/*User data: entry point script that will be executed
on EC2 instance whenever the server is instantiated
*/

