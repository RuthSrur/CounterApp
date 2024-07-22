# Use an official Python runtime as a parent image
FROM python:3.10-slim

WORKDIR /app

# Copy the application code and requirements
COPY main.py requirements.txt ./
COPY static/ static/
COPY templates/ templates/
COPY test_main.py ./

# Install the dependencies
RUN pip install --no-cache-dir -r requirements.txt

EXPOSE 5000

# Define environment variable
ENV FLASK_APP=main.py
ENV FLASK_RUN_HOST=0.0.0.0

# Run app.py when the container launches
CMD ["flask", "run"]
