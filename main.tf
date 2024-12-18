terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

variable "aws_region" {
  description = "The AWS region to deploy resources"
  default     = "ap-south-1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
  description = "The CIDR block for the subnet"
  default     = "10.0.1.0/24"
}

variable "instance_type" {
  description = "Type of EC2 instance"
  default     = "t2.small"
}

variable "ami_id" {
  description = "AMI ID for the instance"
  default     = "ami-0e53db6fd757e38c7"
}

variable "volume_size" {
  description = "Size of the root block device"
  default     = 15
}

variable "volume_type" {
  description = "Type of the root block device volume"
  default     = "gp3"
}

#variable "additional_volume_size" {
  #description = "Size of the additional EBS volume"
  #default     = 20
#}

#variable "additional_volume_type" {
 # description = "Type of the additional EBS volume"
  #default     = "gp3"
#}

variable "additional_volume_size" {
  description = "Size of the additional EBS volume"
  default     = 25
}

variable "additional_volume_type" {
  description = "Type of the additional EBS volume"
  default     = "gp3"
}


variable "security_group_name" {
  description = "Name of the security group"
  default     = "mysecurity"
}

variable "key_name" {
  description = "The key pair to use for the instance"
  default     = "MyNewKey"
}

provider "aws" {
  region = var.aws_region
}

resource "aws_vpc" "myvpc" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "myvpc"
  }
}

resource "aws_subnet" "mysubnet" {
  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = var.subnet_cidr
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "mysubnet"
  }
}

resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "myigw"
  }
}

resource "aws_route_table" "myroute" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }

  tags = {
    Name = "myroute"
  }
}

resource "aws_route_table_association" "myrta" {
  subnet_id      = aws_subnet.mysubnet.id
  route_table_id = aws_route_table.myroute.id
}

resource "aws_security_group" "mysecurity" {
  name        = var.security_group_name
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  tags = {
    Name = var.security_group_name
  }
}

resource "aws_security_group_rule" "public_out" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mysecurity.id
}

resource "aws_security_group_rule" "public_in_ssh" {
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mysecurity.id
}

resource "aws_security_group_rule" "public_in_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mysecurity.id
}

resource "aws_security_group_rule" "public_in_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.mysecurity.id
}

resource "aws_instance" "myprojectinstance" {
  ami                         = var.ami_id
  instance_type               = var.instance_type
  key_name                    = var.key_name
  subnet_id                   = aws_subnet.mysubnet.id
  associate_public_ip_address = true
  vpc_security_group_ids      = [aws_security_group.mysecurity.id]

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  #ebs_block_device {
   # device_name           = "/dev/xvdf"
   # volume_size           = var.additional_volume_size
   # volume_type           = var.additional_volume_type
    #delete_on_termination = true
  #}

  user_data = file("resize.sh")

  tags = {
    Name = "myprojectinstance"
  }
}

# Standalone EBS Volume
resource "aws_ebs_volume" "additional_volume" {
  availability_zone = "ap-south-1a"
  size              = var.additional_volume_size
  #volume_type       = var.additional_volume_type

  tags = {
    Name = "additional-volume"
  }
}

# Attach EBS Volume to EC2 Instance
resource "aws_volume_attachment" "additional_volume_attachment" {
  device_name = "/dev/xvdf"
  volume_id   = aws_ebs_volume.additional_volume.id
  instance_id = aws_instance.myprojectinstance.id
  force_detach = true
}
