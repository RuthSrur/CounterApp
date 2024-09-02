# Use an official Python runtime as a parent image
FROM python:3.10-slim

WORKDIR /app

# Install necessary dependencies including awscli
USER root


# Copy the app and requirements
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

