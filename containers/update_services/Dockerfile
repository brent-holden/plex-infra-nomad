FROM python:3
WORKDIR /app
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir pyyaml python-consul
COPY . .
CMD ["python", "update_services.py"]
