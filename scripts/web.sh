#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y apache2 php libapache2-mod-php php-mysql git ufw

# Desplegar aplicación web
rm -rf /tmp/app /var/www/html/*
git clone https://github.com/josejuansanchez/iaw-practica-lamp.git /tmp/app
cp -r /tmp/app/src/* /var/www/html/
rm -rf /tmp/app

# Configurar conexión con AlejandroBBDD (192.168.57.20)
sed -i "s/localhost/192.168.57.20/" /var/www/html/config.php
sed -i "s/database_name_here/lamp_db/" /var/www/html/config.php
sed -i "s/username_here/lamp_user/" /var/www/html/config.php
sed -i "s/password_here/lamp_password/" /var/www/html/config.php

# Mostrar qué nodo web procesa cada visita
sed -i "s/Simple LAMP web app/Simple LAMP web app - Nodo activo: $(hostname)/" /var/www/html/index.php

chown -R www-data:www-data /var/www/html
systemctl restart apache2

# Cortafuegos de Capa 2: permite SSH de gestión y HTTP (80) solo desde el balanceador
IF_NAT=$(ip -o -4 route show to default | awk '{print $5}' | head -n1)
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow in on "$IF_NAT" to any port 22 proto tcp
ufw allow from 192.168.56.10 to any port 80 proto tcp
ufw --force enable

# Aislar completamente de Internet
ip route del default || true