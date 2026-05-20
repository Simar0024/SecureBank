# Dockerfile
FROM python:3.11-slim
WORKDIR /workspace

# Copy the requirements file into the container first
COPY ./app/requirements.txt /workspace/requirements.txt

# Install all listed production dependencies
RUN pip install --no-cache-dir -r /workspace/requirements.txt

# Copy the rest of your application code
COPY ./app /workspace/app

EXPOSE 8000
USER 10001
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]