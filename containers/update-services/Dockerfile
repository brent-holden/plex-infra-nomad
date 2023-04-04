FROM python:3
ENV CONSUL_HTTP_ADDR=consul.service.consul:8500
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir pyyaml python-consul
WORKDIR /app
COPY . .
CMD ["python", "update-services.py"]
