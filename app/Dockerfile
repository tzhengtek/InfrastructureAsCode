# ==============================================================================
# DOCKERFILE - Recipe to Build Your Flask App Container
# ==============================================================================
FROM python:3.11-slim

LABEL maintainer="Perth Team"
LABEL description="Flask Task Manager API"
LABEL version="1.0"

# Set working directory
WORKDIR /

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends gcc && \
    rm -rf /var/lib/apt/lists/*

# Copy and install Python dependencies
COPY requirements.txt /requirements.txt
RUN pip install --no-cache-dir -r /requirements.txt

# Create app directory as a proper Python package
RUN mkdir -p /app

# Copy all files into /app package directory
COPY __init__.py /app/__init__.py
COPY __main__.py /app/__main__.py
COPY common.py /app/common.py
COPY health_routes.py /app/health_routes.py
COPY tasks_routes.py /app/tasks_routes.py
COPY status_codes.py /app/status_codes.py

# Create non-root user
RUN useradd -m -u 1000 appuser && \
    chown -R appuser:appuser /app

USER appuser

# Expose port
EXPOSE 8080

# Environment variables
ENV PYTHONUNBUFFERED=1

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8080/health').read()"

# Run as a Python package (python -m app)
# This allows relative imports to work correctly
CMD ["python", "-m", "app"]
