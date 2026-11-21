#!/bin/bash
set -e

DOMINIO="alejandro-iaw.duckdns.org"
DIR_HOOKS="/etc/letsencrypt/duckdns"

: "${DUCKDNS_TOKEN:?Falta exportar la variable DUCKDNS_TOKEN}"

mkdir -p "${DIR_HOOKS}"
echo "${DUCKDNS_TOKEN}" > "${DIR_HOOKS}/token"
chmod 600 "${DIR_HOOKS}/token"

cat > "${DIR_HOOKS}/auth.sh" <<'HOOK'
#!/bin/bash
set -e
TOKEN="$(cat /etc/letsencrypt/duckdns/token)"
SUBDOMINIO="${CERTBOT_DOMAIN%.duckdns.org}"
[[ "$(curl -s "https://www.duckdns.org/update?domains=${SUBDOMINIO}&token=${TOKEN}&txt=${CERTBOT_VALIDATION}")" = "OK" ]]
sleep 30
HOOK

cat > "${DIR_HOOKS}/cleanup.sh" <<'HOOK'
#!/bin/bash
TOKEN="$(cat /etc/letsencrypt/duckdns/token)"
SUBDOMINIO="${CERTBOT_DOMAIN%.duckdns.org}"
curl -s "https://www.duckdns.org/update?domains=${SUBDOMINIO}&token=${TOKEN}&txt=${CERTBOT_VALIDATION}&clear=true" > /dev/null
HOOK

chmod +x "${DIR_HOOKS}/auth.sh" "${DIR_HOOKS}/cleanup.sh"

certbot --authenticator manual --installer apache \
    --preferred-challenges dns \
    --manual-auth-hook "${DIR_HOOKS}/auth.sh" \
    --manual-cleanup-hook "${DIR_HOOKS}/cleanup.sh" \
    -d "${DOMINIO}" \
    --non-interactive --agree-tos \
    --register-unsafely-without-email \
    --redirect

certbot renew --dry-run
systemctl reload apache2