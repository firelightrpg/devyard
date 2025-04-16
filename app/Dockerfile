FROM python:3.12-slim

WORKDIR /app
COPY main.py .
RUN PIP_ROOT_USER_ACTION=ignore pip install --no-cache-dir fastapi uvicorn requests kubernetes

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
