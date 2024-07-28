# Use an official Python runtime as a parent image
FROM python:3.10-slim

WORKDIR /app

# Install necessary dependencies including awscli
RUN apt-get update && \
    apt-get install -y curl unzip && \
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
    unzip awscliv2.zip && \
    ./aws/install && \
    rm -rf awscliv2.zip aws

# Copy the application code and requirements
COPY main.py requirements.txt test_main.py ./
COPY static/ static/
COPY templates/ templates/

# Install the dependencies
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 5000

# Define environment variable
ENV FLASK_APP=main.py
ENV FLASK_RUN_HOST=0.0.0.0

# Run app.py when the container launches
CMD ["flask", "run"]

