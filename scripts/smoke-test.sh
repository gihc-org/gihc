#!/usr/bin/env bash
set -euo pipefail

# Verificerer den offentlige GIHC-side udefra.
#
# Brug:
#   ./scripts/smoke-test.sh
#   ./scripts/smoke-test.sh https://gihc.online

BASE_URL="${1:-https://gihc.online}"
BASE_URL="${BASE_URL%/}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

fail() {
    echo "FAIL: $*" >&2
    exit 1
}

echo "==> Tester ${BASE_URL}"

curl -fsS --max-time 20 "${BASE_URL}/" -o "${TMP_DIR}/index.html"
curl -fsS --max-time 20 "${BASE_URL}/assets/gihc-emblem.webp" \
    -o "${TMP_DIR}/logo.webp" \
    -D "${TMP_DIR}/logo-headers.txt"

grep -q '<title>GIHC — Global Institute of Hybrid Cleverness</title>' \
    "${TMP_DIR}/index.html" || fail "forsidens titel mangler"
grep -q 'gihc-emblem.webp' "${TMP_DIR}/index.html" \
    || fail "logoet refereres ikke fra forsiden"
grep -qi '^content-type: image/webp' "${TMP_DIR}/logo-headers.txt" \
    || fail "logoet serveres ikke som image/webp"

curl -fsS --max-time 20 "${BASE_URL}/healthz" \
    | grep -qx 'ok' || fail "health endpoint svarer ikke ok"

STATUS="$(curl -sS --max-time 20 -o /dev/null -w '%{http_code}' "${BASE_URL}/not-here")"
[ "$STATUS" = "404" ] || fail "ukendt sti giver HTTP ${STATUS}, forventet 404"

curl -fsS --max-time 20 -D "${TMP_DIR}/headers.txt" \
    -o /dev/null "${BASE_URL}/"
grep -qi '^content-security-policy:' "${TMP_DIR}/headers.txt" \
    || fail "Content-Security-Policy mangler"
grep -qi '^x-content-type-options: nosniff' "${TMP_DIR}/headers.txt" \
    || fail "X-Content-Type-Options mangler"
grep -qi '^x-frame-options: DENY' "${TMP_DIR}/headers.txt" \
    || fail "X-Frame-Options mangler"

if [[ "$BASE_URL" == https://* ]]; then
    curl -fsS --max-time 20 -o /dev/null \
        -w 'TLS verify result: %{ssl_verify_result}\n' "${BASE_URL}/" \
        | grep -q 'TLS verify result: 0' \
        || fail "TLS-certifikatet kunne ikke verificeres"
fi

echo "PASS: forside, logo, health, 404, sikkerhedsheadere og TLS er OK"

