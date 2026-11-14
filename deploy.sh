#!/usr/bin/env bash
set -euo pipefail
[ "$(id -u)" -eq 0 ] || { echo "Run with sudo: sudo bash deploy.sh"; exit 1; }
DIR="$(cd "$(dirname "$0")" && pwd)"
apt-get update -y && apt-get install -y nginx
mkdir -p /var/www/pagesim
install -m 644 -o www-data -g www-data "$DIR/index.html" /var/www/pagesim/index.html
cat > /etc/nginx/sites-available/pagesim <<'CONF'
server {
    listen 80 default_server;
    server_name _;
    root /var/www/pagesim;
    index index.html;
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options SAMEORIGIN;
    gzip on; gzip_types text/html text/css application/javascript;
    location / { try_files $uri $uri/ =404; }
}
CONF
ln -sf /etc/nginx/sites-available/pagesim /etc/nginx/sites-enabled/pagesim
rm -f /etc/nginx/sites-enabled/default
nginx -t
systemctl enable --now nginx
systemctl reload nginx
if ufw status 2>/dev/null | grep -q "Status: active"; then ufw allow 'Nginx Full'; fi
echo "Deployed. Open http://localhost/"
