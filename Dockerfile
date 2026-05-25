# Dockerfile
FROM python:3.11-slim

WORKDIR /workspace

# Install system dependencies if required
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Upgrade installation baseline components to clear lower-level build CVEs
RUN pip install --no-cache-dir --upgrade pip setuptools wheel==0.46.2

# Copy and install requirement paths safely
COPY app/requirements.txt /workspace/requirements.txt
RUN pip install --no-cache-dir -r /workspace/requirements.txt

COPY . /workspace

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]