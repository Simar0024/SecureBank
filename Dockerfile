# Dockerfile
FROM python:3.11-slim
WORKDIR /workspace
COPY ./app /workspace/app
RUN pip install --no-cache-dir fastapi uvicorn PyJWT pydantic
EXPOSE 8000
# Run as non-privileged system user profile for container hardening compliance
USER 10001
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]