#!/usr/bin/env bash
set -euo pipefail

# Begrænser certifikatudstedelse for gihc.online til Let's Encrypt.
# Idempotent: opretter kun recorden, hvis den ikke allerede findes.
#
# Credentials hentes fra pass:
#   pass simply/account
#   pass simply/api-key

DOMAIN="gihc.online"
RECORD_NAME="${RECORD_NAME:-@}"
CAA_VALUE="${CAA_VALUE:-0 issue \"letsencrypt.org\"}"

SIMPLY_ACCOUNT="$(pass simply/account)"
SIMPLY_API_KEY="$(pass simply/api-key)"
API_URL="https://api.simply.com/2/my/products/${DOMAIN}/dns/records/"

echo "==> Henter DNS-records for ${DOMAIN}"
RECORDS="$(curl -fsS -u "${SIMPLY_ACCOUNT}:${SIMPLY_API_KEY}" "${API_URL}")"

EXISTING="$(RECORD_NAME="$RECORD_NAME" CAA_VALUE="$CAA_VALUE" \
    python3 -c '
import json, os, sys
records = json.load(sys.stdin).get("records", [])
name = os.environ["RECORD_NAME"]
expected = os.environ["CAA_VALUE"]
values = [
    r.get("data", "")
    for r in records
    if r.get("type") == "CAA" and r.get("name") == name
]
if expected in values:
    print("exact")
elif values:
    print("different:" + ",".join(values))
else:
    print("missing")
' <<<"$RECORDS")"

case "$EXISTING" in
    exact)
        echo "==> CAA-record findes allerede"
        exit 0
        ;;
    missing)
        ;;
    different:*)
        echo "==> Der findes en anden CAA-record: ${EXISTING#different:}" >&2
        echo "    Ret den bevidst i Simply.com i stedet for at tilføje en konflikt." >&2
        exit 1
        ;;
    *)
        echo "==> Uventet CAA-status: ${EXISTING}" >&2
        exit 1
        ;;
esac

PAYLOAD="$(RECORD_NAME="$RECORD_NAME" CAA_VALUE="$CAA_VALUE" python3 -c '
import json, os
print(json.dumps({
    "type": "CAA",
    "name": os.environ["RECORD_NAME"],
    "data": os.environ["CAA_VALUE"],
    "ttl": 3600,
}))
')"

echo "==> Opretter CAA-record for ${DOMAIN}"
curl -fsS -u "${SIMPLY_ACCOUNT}:${SIMPLY_API_KEY}" \
    -X POST "${API_URL}" \
    -H "Content-Type: application/json" \
    -d "$PAYLOAD" \
    -o /dev/null

echo "==> Oprettet"

