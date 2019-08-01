provider "aws" {
  region = "ap-northeast-1"
  access_key = "AKIA2NIBY3N5AY3BENP5"
  secret_key = "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"
}


resource "aws_vpc" "user10-vpc" {
  cidr_block           = "110.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    Name = "user10-vpc"
  }
}


resource "aws_subnet" "user10_pub_1a" {
  vpc_id            = "${aws_vpc.user10-vpc.id}"
  availability_zone = "ap-northeast-1a"
  cidr_block        = "110.0.1.0/24"

  tags = {
    Name = "user10_pub_1a"
  }
}

resource "aws_subnet" "user10_pub_1b" {
  vpc_id            = "${aws_vpc.user10-vpc.id}"
  availability_zone = "ap-northeast-1d"
  cidr_block        = "110.0.2.0/24"

  tags = {
    Name = "user10_pub_1b"
  }
}

resource "aws_internet_gateway" "user10-igw" {
  vpc_id = "${aws_vpc.user10-vpc.id}"

  tags = {
    Name = "user10-igw"
  }
}

resource "aws_eip" "nat_user10_1a" {
  vpc = true
}

resource "aws_eip" "nat_user10_1b" {
  vpc = true
}

resource "aws_nat_gateway" "user10_1a" {
  allocation_id = "${aws_eip.nat_user10_1a.id}"
  subnet_id     = "${aws_subnet.user10_pub_1a.id}"
}

resource "aws_nat_gateway" "user10_1b" {
  allocation_id = "${aws_eip.nat_user10_1b.id}"
  subnet_id     = "${aws_subnet.user10_pub_1b.id}"
}


# dev_public
resource "aws_route_table" "user10_pub_rt" {
  vpc_id = "${aws_vpc.user10-vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.user10-igw.id}"
  }
}

resource "aws_route_table_association" "user10_pub" {
  subnet_id      = "${aws_subnet.user10_pub_1a.id}"
  route_table_id = "${aws_route_table.user10_pub_rt.id}"
}

# dev_private

resource "aws_route_table" "user10_prv_rt" {
  vpc_id = "${aws_vpc.user10-vpc.id}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.user10_1b.id}"
  }
}

resource "aws_route_table_association" "user10_prv" {
  subnet_id      = "${aws_subnet.user10_pub_1b.id}"
  route_table_id = "${aws_route_table.user10_prv_rt.id}"
}


resource "aws_default_security_group" "user10_default" {
  vpc_id = "${aws_vpc.user10-vpc.id}"

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "user10-web01-SG" {
  name        = "user10-web01-SG"
  description = "open ssh port for user10-web01"
  vpc_id = "${aws_vpc.user10-vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
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

resource "aws_eip" "user10-web01-eip" {
  instance = "${aws_instance.user10-web01.id}"
  vpc      = true
}

resource "aws_instance" "user10-web01" {
  ami               = "${var.amazon_linux}"
  availability_zone = "ap-northeast-1a"
  instance_type     = "t2.nano"
  key_name          = "${var.user10_keyname}"

  vpc_security_group_ids = [
    "${aws_security_group.user10-web01-SG.id}",
    "${aws_default_security_group.user10_default.id}",
  ]

  subnet_id =  "${aws_subnet.user10_pub_1a.id}"
  associate_public_ip_address = true

  tags = {
  	Name= "user10-web01"
	}
}


variable "amazon_linux" {
  # Amazon Linux AMI 2017.03.1 (HVM), SSD Volume Type - ami-4af5022c
  default = "ami-4af5022c"
}

variable "user10_keyname" {
  default = "user10-key"
}

resource "aws_key_pair" "user10-key" {
    key_name    = "user10-key"
    public_key  = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDcSPSyG1o2Vh1ImBleWwm/5rRVnXn5Wc1INqG2cM7Opy7sCMp7rHjAi92bQ4AMbfM5Sn/s7iibtV09viIUH10vCDY8JI645y4DZIcOkkRyH09sUH4XFsng0pSRjz1rTByoxbx9m6Pg0MA8vpwggGcq66CM04iDTXVHZfsREkaWA/2darmojWd8OKdl05VM6TlQZR0RtLXCKDqvaHz0Yb+WtsEWgWBezv3kZx6x9t6AMas9TY4SA50TU0RXUbzJWwDawLSkcOPfyVbxEp2DxjSdhxEu99WaRbuc9piEAuAXAJjdNR1jSCA/W94enC9+H6UT/8M/XwGHJWFQ7swqDkFL root@ip-172-31-41-173"
}
