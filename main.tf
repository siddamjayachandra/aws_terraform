terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = "ap-south-1"
}

#data "aws_availability_zones" "available" {
# state = "available"
#}

resource "aws_vpc" "myvpc" {
  cidr_block = "10.0.0.0/16"
  #instance_tenancy = "dedicated"

  tags = {
    Name = "myvpc"
  }
}


#variable "azs" {

#type        = list(string)

#description = "Availability Zones"

#default     = ["ap-south-1a"]

#} 

#variable "public" {

# type = list(string)

#description = "Public Subnet CIDR values"

#default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]

#}

#variable "azs" {

# type = list(string)

#description = "Availability Zones"

#default = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]

#}

resource "aws_subnet" "mysubnet" {
  #count      = length(var.public)
  vpc_id = aws_vpc.myvpc.id
  #cidr_block = element(var.public, count.index)
  cidr_block = "10.0.1.0/24"
  #availability_zone = element(var.azs, count.index)
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


#resource "aws_eip" "myeip" {
# depends_on = [aws_internet_gateway.myigw]
#}


resource "aws_route_table" "myroute" {
  vpc_id = aws_vpc.myvpc.id
  #subnet_id = aws_subnet.mysubnet.id

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
  name        = "mysecurity"
  description = "Allow TLS inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.myvpc.id

  tags = {
    Name = "mysecurity"
  }
}


resource "aws_security_group_rule" "public_out" {

  type = "egress"

  from_port = 0

  to_port = 0

  protocol = "-1"

  cidr_blocks = ["0.0.0.0/0"]



  security_group_id = aws_security_group.mysecurity.id

}


resource "aws_security_group_rule" "public_in_ssh" {

  type = "ingress"

  from_port = 22

  to_port = 22

  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.mysecurity.id

}


resource "aws_security_group_rule" "public_in_http" {

  type = "ingress"

  from_port = 80

  to_port = 80

  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.mysecurity.id

}


resource "aws_security_group_rule" "public_in_https" {

  type = "ingress"

  from_port = 443

  to_port = 443

  protocol = "tcp"

  cidr_blocks = ["0.0.0.0/0"]

  security_group_id = aws_security_group.mysecurity.id

}

resource "aws_instance" "myprojectinstance" {
  ami           = "ami-0e53db6fd757e38c7"
  instance_type = "t2.small"
  key_name      = "MyNewKey"
  subnet_id     = aws_subnet.mysubnet.id
  #subnet_id                   = aws_subnet.myprivatesubnet.id
  associate_public_ip_address = true
  #security_group_id = aws_security_group.mysecurity.id
  #vpc_id            = aws_vpc.myvpc.id
  vpc_security_group_ids = [aws_security_group.mysecurity.id]
  #vpc_security_group_ids = [aws_security_group.myprivatesecurity.id]
  #security_group_id = aws_security_group.mysecurity.id

  root_block_device {
    volume_size = 10 # 10 GB storage
    volume_type = "gp3"
  }

  tags = {
    Name = "myprojectinstance"
  }
}

#resource "aws_instance" "myprojectprivateinstance" {
#ami           = "ami-0e53db6fd757e38c7"
#instance_type = "t2.micro"
#key_name      = "MyALB"
#subnet_id     = aws_subnet.myprivatesubnet.id
#subnet_id                   = aws_subnet.myprivatesubnet.id
#associate_public_ip_address = false
#security_group_id = aws_security_group.mysecurity.id
#vpc_id            = aws_vpc.myvpc.id
#vpc_security_group_ids = [aws_security_group.myprivatesecurity.id]
#vpc_security_group_ids = [aws_security_group.myprivatesecurity.id]
#security_group_id = aws_security_group.mysecurity.id
#user_data = file("myprivate.sh")

#tags = {
#Name = "myprojectprivateinstance"
#}
#}


#resource "aws_instance" "my_testing" {
#ami = "ami-0e53db6fd757e38c7"
#instance_type = "t2.micro"
#key_name = "MyALB"
#subnet_id     = aws_subnet.myprivatesubnet.id
#associate_public_ip_address = false
#vpc_security_group_ids = [aws_security_group.myprivatesecurity.id]
#user_data = file("testing.sh")

#tags = {
#Name = "my_testing"
#}
#


#resource "aws_instance" "myprojectprivateinstance" {
#ami           = "ami-0e53db6fd757e38c7"
#instance_type = "t2.micro"
#key_name      = "MyALB"
#subnet_id     = aws_subnet.myprivatesubnet.id
#subnet_id                   = aws_subnet.myprivatesubnet.id
#associate_public_ip_address = false
#security_group_id = aws_security_group.mysecurity.id
#vpc_id            = aws_vpc.myvpc.id
#vpc_security_group_ids = [aws_security_group.myprivatesecurity.id]
#vpc_security_group_ids = [aws_security_group.myprivatesecurity.id]
#security_group_id = aws_security_group.mysecurity.id
#user_data = file("myprivate.sh")

#tags = {
#Name = "myprojectprivateinstance"
#}
#}


#resource "aws_instance" "my_testing" {
#ami = "ami-0e53db6fd757e38c7"
#instance_type = "t2.micro"
#key_name = "MyALB"
#subnet_id     = aws_subnet.myprivatesubnet.id
#associate_public_ip_address = false
#vpc_security_group_ids = [aws_security_group.myprivatesecurity.id]
#user_data = file("testing.sh")

#tags = {
#Name = "my_testing"
#}
#