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
curl -fsS --max-time 20 "${BASE_URL}/en/" -o "${TMP_DIR}/index-en.html"
curl -fsS --max-time 20 "${BASE_URL}/assets/gihc-emblem.svg" \
    -o "${TMP_DIR}/logo.svg" \
    -D "${TMP_DIR}/logo-headers.txt"
curl -fsS --max-time 20 "${BASE_URL}/assets/gihc-badge-75mm.zip" \
    -o "${TMP_DIR}/gihc-badge-75mm.zip" \
    -D "${TMP_DIR}/download-headers.txt"

grep -q '<title>GIHC — Global Institute of Hybrid Cleverness</title>' \
    "${TMP_DIR}/index.html" || fail "forsidens titel mangler"
grep -q 'gihc-emblem.svg' "${TMP_DIR}/index.html" \
    || fail "logoet refereres ikke fra forsiden"
grep -qi '^content-type: image/svg+xml' "${TMP_DIR}/logo-headers.txt" \
    || fail "logoet serveres ikke som image/svg+xml"
grep -q '<svg' "${TMP_DIR}/logo.svg" \
    || fail "logoet er ikke SVG"
if grep -q '<image' "${TMP_DIR}/logo.svg"; then
    fail "SVG-logoet indeholder et indlejret bitmap"
fi
grep -q 'gihc-badge-75mm.zip' "${TMP_DIR}/index.html" \
    || fail "downloadlinket til mærkepakken mangler"
grep -q 'mailto:kristian.n.jensen@gmail.com' "${TMP_DIR}/index.html" \
    || fail "e-mailkontakt mangler"
grep -q 'tel:+4552699443' "${TMP_DIR}/index.html" \
    || fail "telefonkontakt mangler"
grep -q '<html lang="en">' "${TMP_DIR}/index-en.html" \
    || fail "engelsk sprogkode mangler"
grep -q 'The association for playful preparedness' "${TMP_DIR}/index-en.html" \
    || fail "engelsk hero-tekst mangler"
grep -q 'href="/"' "${TMP_DIR}/index-en.html" \
    || fail "sprogskift til dansk mangler"
grep -q 'href="/en/"' "${TMP_DIR}/index.html" \
    || fail "sprogskift til engelsk mangler"
grep -qi '^content-type: application/zip' "${TMP_DIR}/download-headers.txt" \
    || fail "mærkepakken serveres ikke som application/zip"
[ "$(head -c 2 "${TMP_DIR}/gihc-badge-75mm.zip")" = "PK" ] \
    || fail "mærkepakken er ikke en gyldig ZIP-fil"

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

echo "PASS: dansk og engelsk forside, sprogskift, vektorlogo, mærkedownload, kontaktlinks, health, 404, sikkerhedsheadere og TLS er OK"

