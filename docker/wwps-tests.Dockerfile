FROM python:3.12-slim
WORKDIR /app

COPY appsettings.json appsettings.json
COPY wwps/ ./wwps/
COPY Resources/ ./Resources/
COPY dataDownload/ ./dataDownload/
COPY Database/ ./Database/
COPY tests/ ./tests/
COPY Tools/ ./Tools/

RUN apt-get update && \
    apt-get install -y --no-install-recommends postgresql-client && \
    rm -rf /var/lib/apt/lists/*

COPY requirements-dev.txt .
COPY requirements.txt .
RUN pip install --no-cache-dir --root-user-action ignore -r requirements.txt
RUN pip install --no-cache-dir --root-user-action ignore -r requirements-dev.txt


CMD ["pytest"]