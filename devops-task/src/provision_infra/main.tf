terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"
}

provider "aws" {
  profile = "default"
  region  = "us-west-2"
}

resource "aws_vpc" "vpc" {
    cidr_block = "10.0.0.0/24"
    enable_dns_support   = true
    enable_dns_hostnames = true
    tags       = {
        Name = "Terraform VPC"
    }
}

resource "aws_internet_gateway" "internet_gateway" {
    vpc_id = aws_vpc.vpc.id
}

data "aws_availability_zone" "example" {
  name = "us-west-2b"
}

resource "aws_subnet" "pub_subnet" {
    vpc_id                  = aws_vpc.vpc.id
    cidr_block              = cidrsubnet(aws_vpc.vpc.cidr_block, 4, var.az_number[data.aws_availability_zone.example.name_suffix])
}


resource "aws_route_table" "public" {
    vpc_id = aws_vpc.vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.internet_gateway.id
    }
}

resource "aws_route_table_association" "route_table_association" {
    subnet_id      = aws_subnet.pub_subnet.id
    route_table_id = aws_route_table.public.id
}

resource "aws_security_group" "ecs_sg" {
    vpc_id      = aws_vpc.vpc.id

    ingress {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    ingress {
        from_port       = 8000
        to_port         = 8000
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }


    egress {
        from_port       = 0
        to_port         = 65535
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

    egress {
        from_port       = 8000
        to_port         = 8000
        protocol        = "tcp"
        cidr_blocks     = ["0.0.0.0/0"]
    }

}

resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    protocol  = -1
    self      = true
    from_port = 0
    to_port   = 0
  }
 
  ingress {
    protocol    = "tcp"
    self        = false
    from_port   = 22
    to_port     = 22
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecr_repository" "php-app" {
    name  = "php-app"
}

resource "aws_ecs_cluster" "ecs_cluster" {
    name  = "my-php-app-cluster"
}

resource "aws_ecs_task_definition" "task_definition" {
  family                = "php-app"
  container_definitions = jsonencode([
    {
      name	= "php-app"
      image	= "435901930649.dkr.ecr.us-west-2.amazonaws.com/php-app:latest"
      cpu	= 2
      memory	= 300
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort = 8000
	}
      ]   
    },
  ])
}

resource "aws_ecs_service" "php-app-worker" {
  name            = "php-app-worker"
  cluster         = aws_ecs_cluster.ecs_cluster.id
  task_definition = aws_ecs_task_definition.task_definition.arn
  desired_count   = 1
}

resource "aws_key_pair" "php_app" {
  key_name   = "php-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCCx6D44j1TaaclAENXnjkYBFZdpTcraaNSFfuBtWNCWwQJpPgCZ3Tn6rV+Ircv0PxtIfqbztPR6Xv26X3jaSs5TazhI7Xd2Fkdhf7ix3uxCItGau2RJI7c9dNPMYDncUzqqODe2/WWAFYYf5wyqiboQ8dZ5MkLA931nhblHdsJ4pkMdrV0xi0iWtcuPsaPD85VNZmSMRppTN6NoGF7QdttIy6y0cdvdbe4zEaiPdexKAfJAsLhDfm07hzH6mqgT7sEtzUX72wkc5LqcoSS8AGLGxI2ucAYN2ymYa7gIRHj38szQvInCYCGbeOJrssxdV7O2fU+FZ6gsxLfZ3QXDTN/"
}

resource "aws_iam_role" "ecs_role" {
  name = "ecs_role"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

resource "aws_iam_instance_profile" "ecs_profile" {
  name = "ecs_profile"
  role = "${aws_iam_role.ecs_role.name}"
}

resource "aws_iam_role_policy" "test_policy" {
  name = "test_policy"
  role = "${aws_iam_role.ecs_role.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ecs:*",
        "ecr:*"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}

resource "aws_instance" "php_server" {
  ami           = "ami-091500e582a8cd219"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.pub_subnet.id
  associate_public_ip_address = true
  key_name = aws_key_pair.php_app.key_name
  iam_instance_profile = "${aws_iam_instance_profile.ecs_profile.name}"
  tags = {
    Name = "PhpAppServer"
  }
  user_data	= <<EOF
  #!/bin/bash
  echo "ECS_CLUSTER=my-php-app-cluster" >> /etc/ecs/ecs.config
  EOF
}

