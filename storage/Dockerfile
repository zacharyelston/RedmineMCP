FROM python:3.11-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    postgresql-client \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements
COPY pyproject.toml /app/
COPY uv.lock /app/

# Install Python dependencies
RUN pip install --no-cache-dir pip --upgrade && \
    pip install --no-cache-dir -e .

# Copy application code
COPY . /app/

# Expose the Flask port
EXPOSE 9000

# Start the application
CMD ["gunicorn", "--bind", "0.0.0.0:9000", "--reuse-port", "--reload", "main:app"]