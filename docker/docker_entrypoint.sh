#!/bin/sh
# Entrypoint of WWPS' docker container.
# No point in running it manually
set -e

# Remplace the sensitive information of .env into the appsettings
python - <<'EOF'
import json
import os

print("Running docker entrypoint...")
with open("appsettings.json") as f:
    cfg = json.load(f)

    #cfg["Port"] = os.environ['WWPS_PORT']
    cfg["PostgresConnectionString"] = (
        f"postgresql://{os.environ['POSTGRES_USER']}:{os.environ['POSTGRES_PASSWORD']}"
        f"@{os.environ['POSTGRES_HOST']}:{os.environ['POSTGRES_PORT']}/{os.environ['POSTGRES_DB']}"
    )
    cfg["DashboardToken"] = os.environ["DASHBOARD_TOKEN"]
    cfg["AdminToken"] = os.environ["ADMIN_TOKEN"]

    with open("appsettings.json", "w") as f:
        json.dump(cfg, f, indent=4)
EOF
echo "Finished copying .env variables into appsettings.json"

python -m wwps