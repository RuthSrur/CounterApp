provider "aws" {
  region = "us-east-1"  # Your preferred region
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "main-vpc"
  }
}

# Create Subnet
resource "aws_subnet" "subnet" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "main-subnet"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main-igw"
  }
}

# Create Route Table
resource "aws_route_table" "routetable" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "main-route-table"
  }
}

# Associate Route Table with Subnet
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet.id
  route_table_id = aws_route_table.routetable.id
}

# Create Security Group
resource "aws_security_group" "instance_sg" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["93.173.236.169/32"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["18.206.107.24/29"]
  }

  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["93.173.236.169/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "instance-sg"
  }
}

# Fetch the latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["137112412989"]  # Amazon's official account ID for Amazon Linux 2
}

# Create EC2 instance
resource "aws_instance" "docker_instance" {
  ami                    = data.aws_ami.amazon_linux_2.id
  instance_type          = "t2.micro"
  key_name               = "My-key"  # Add your key pair name here
  subnet_id              = aws_subnet.subnet.id
  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = <<-EOF
            #!/bin/bash
            # Install Docker
            amazon-linux-extras install docker -y
            service docker start
            usermod -aG docker ec2-user
            
            # Install Docker Compose
            curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
            chmod +x /usr/local/bin/docker-compose

            # Create Docker network
            docker network create jenkins

            # Run Docker-in-Docker container
            docker run \
              --name docker-in-docker \
              --detach \
              --restart always \
              --privileged \
              --network jenkins \
              --network-alias docker \
              --env DOCKER_TLS_CERTDIR=/certs \
              --volume jenkins-docker-certs:/certs/client \
              --volume jenkins-data:/var/jenkins_home \
              --publish 2376:2376 \
              docker:dind \
              --storage-driver overlay2

            # Create Dockerfile for Jenkins with Docker
            cat <<-EOD > Dockerfile
            FROM jenkins/jenkins:2.426.3-jdk17
            USER root
            RUN apt-get update && apt-get install -y lsb-release
            RUN curl -fsSLo /usr/share/keyrings/docker-archive-keyring.asc https://download.docker.com/linux/debian/gpg
            RUN echo "deb [arch=\$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.asc] https://download.docker.com/linux/debian \$(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
            RUN apt-get update && apt-get install -y docker-ce-cli
            USER jenkins
            EOD

            # Build Jenkins Docker image
            docker build -t jenkins_with_docker:one .

            # Check if the build was successful
            if [ $? -ne 0 ]; then
              echo "Jenkins Docker image build failed" >&2
              exit 1
            fi

            # Run Jenkins with Docker container
            docker run \
              --name jenkins_docker \
              --restart always \
              --detach \
              --network jenkins \
              --env DOCKER_HOST=tcp://docker:2376 \
              --env DOCKER_CERT_PATH=/certs/client \
              --env DOCKER_TLS_VERIFY=1 \
              --publish 8080:8080 \
              --publish 50000:50000 \
              --volume jenkins-data:/var/jenkins_home \
              --volume jenkins-docker-certs:/certs/client:ro \
              jenkins_with_docker:one

            # Check if the Jenkins container is running
            if [ $(docker ps -q -f name=jenkins_docker | wc -l) -eq 0 ]; then
              echo "Jenkins Docker container is not running" >&2
              exit 1
            fi
            EOF


  tags = {
    Name = "DockerInstance"
  }
}

output "instance_id" {
  value = aws_instance.docker_instance.id
}

output "public_ip" {
  value = aws_instance.docker_instance.public_ip
}
