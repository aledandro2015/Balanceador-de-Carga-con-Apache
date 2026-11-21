#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

DOMINIO="alejandro-iaw.duckdns.org"

apt-get update -y
apt-get install -y apache2 curl certbot python3-certbot-apache ufw

a2enmod proxy proxy_http proxy_balancer lbmethod_byrequests headers rewrite ssl

# Definir grupo de servidores web de Capa 2 con reparto equitativo de peticiones
cat > /etc/apache2/conf-available/grupo-web.conf <<CONF
<Proxy "balancer://grupo_servidores">
    BalancerMember "http://192.168.56.11:80"
    BalancerMember "http://192.168.56.12:80"
    ProxySet lbmethod=byrequests
</Proxy>
CONF
a2enconf grupo-web

# Configurar VirtualHost HTTP (Certbot generará después el VirtualHost HTTPS y la redirección)
cat > /etc/apache2/sites-available/balanceador.conf <<CONF
<VirtualHost *:80>
    ServerName ${DOMINIO}

    ProxyPreserveHost On
    RequestHeader set X-Forwarded-Proto expr=%{REQUEST_SCHEME}

    ProxyPass        / balancer://grupo_servidores/
    ProxyPassReverse / balancer://grupo_servidores/
</VirtualHost>
CONF

a2dissite 000-default.conf
a2ensite balanceador.conf
apache2ctl configtest
systemctl restart apache2

# Cortafuegos de Capa 1: puertos públicos 80 y 443 + SSH de gestión
IF_NAT=$(ip -o -4 route show to default | awk '{print $5}' | head -n1)
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow in on "$IF_NAT" to any port 22 proto tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

# Impedir enrutamiento directo hacia la subred de base de datos (Capa 3)
ip route add blackhole 192.168.57.0/24
