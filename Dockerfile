# Use Python runtime as a parent image
FROM python:3.10-slim

WORKDIR /app

# Install dependencies
USER root

RUN apt-get update && \
    apt-get install -y curl unzip sudo && \
    apt-get clean

# Copy app and requirements
COPY main.py requirements.txt test_main.py ./
COPY static/ static/
COPY templates/ templates/

# Install Python dependencies
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 8081

# Define environment variables
ENV FLASK_APP=main.py
ENV FLASK_RUN_PORT=8081
ENV FLASK_RUN_HOST="0.0.0.0"

# Run application
CMD ["flask", "run", "--host=0.0.0.0", "--port=8081"]
