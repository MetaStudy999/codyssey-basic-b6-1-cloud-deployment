#!/usr/bin/env bash
set -euxo pipefail
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y nginx
cat > /var/www/html/index.html <<'HTML'
<!doctype html>
<html lang="en">
<head><meta charset="utf-8"><title>Codyssey B6-1</title></head>
<body><h1>Hello Cloud</h1><p>Codyssey Basic B6-1 is running on AWS EC2.</p></body>
</html>
HTML
printf 'OK\n' > /var/www/html/health
systemctl enable nginx
systemctl restart nginx
