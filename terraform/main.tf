provider "aws" {
  region = "us-east-1"
}

module "vpc" {
  source             = "./modules/vpc"
  cidr_block         = "10.0.0.0/16"
  name               = "main-vpc"
  subnet_cidr_block  = "10.0.1.0/24"
  subnet_name        = "main-subnet"
  igw_name           = "main-igw"
  route_table_name   = "main-route-table"
}

module "security_group" {
  source = "./modules/security_group"
  vpc_id = module.vpc.vpc_id
  name   = "instance-sg"
}

module "ec2_instance" {
  source            = "./modules/ec2_instance"
  instance_type     = "t2.micro"
  key_name          = "My-key"
  subnet_id         = module.vpc.subnet_id
  security_group_ids = [module.security_group.security_group_id]
  user_data         = <<-EOF
                #!/bin/bash
                # Install Docker
                amazon-linux-extras install docker -y
                service docker start
                usermod -aG docker ec2-user

                # Install Docker Compose
                curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
                chmod +x /usr/local/bin/docker-compose

                # Install AWS CLI
                curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                unzip awscliv2.zip
                sudo ./aws/install
                rm -rf awscliv2.zip aws

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
                FROM jenkins/jenkins:2.452.3-jdk17
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
  name               = "DockerInstance"
}

output "instance_id" {
  value = module.ec2_instance.instance_id
}

output "public_ip" {
  value = module.ec2_instance.public_ip
}
