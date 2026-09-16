# Use official lightweight Python base image (Python 3.14)
FROM python:3.14-slim

# Recommended environment variables for Python in containers
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Set working directory inside the container
WORKDIR /app

# Install essential system dependencies (crucial for compiling C-extensions in newer Python versions)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy the entire project source code into the working directory
COPY . .

# Expose the internal port where Gunicorn will run
EXPOSE 8000

# Default command to start the application with Gunicorn
CMD ["gunicorn", "core.wsgi:application", "--bind", "0.0.0.0:8000", "--workers", "3"]