# ==========================
# Runtime stage
# ==========================
FROM python:3.13-slim as wwps

WORKDIR /app

# Install PostgreSQL client for psql
RUN apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client && \
    rm -rf /var/lib/apt/lists/*

COPY requirements-dev.txt .
COPY requirements.txt .
RUN pip install --no-cache-dir --root-user-action ignore -r requirements.txt
RUN pip install --no-cache-dir --root-user-action ignore -r requirements-dev.txt

COPY appsettings.example.json .
COPY wwps/ ./wwps/
COPY Resources/ ./Resources/
COPY dataDownload/ ./dataDownload/
COPY Database/ ./Database/

EXPOSE 8080

COPY docker_entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
