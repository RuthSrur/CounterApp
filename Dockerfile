# Use an official Python runtime as a parent image
FROM python:3.10-slim

WORKDIR /app

# Install necessary dependencies including awscli
USER root

# Install dependencies and AWS CLI
RUN apt-get update && \
    apt-get install -y curl unzip sudo && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws && \
    apt-get clean

# Copy the app and requirements
COPY main.py requirements.txt test_main.py ./
COPY static/ static/
COPY templates/ templates/

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 5000

# Define environment variables
ENV FLASK_APP=main.py
ENV FLASK_RUN_HOST=0.0.0.0

# Run application
CMD ["flask", "run"]
