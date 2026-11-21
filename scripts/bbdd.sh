#!/bin/bash
set -e
export DEBIAN_FRONTEND=noninteractive

apt-get update -y
apt-get install -y mariadb-server git ufw

# Escuchar únicamente en la interfaz de la subred de datos
sed -i "s/^bind-address.*/bind-address = 192.168.57.20/" /etc/mysql/mariadb.conf.d/50-server.cnf
systemctl restart mariadb

# Importar esquema de base de datos de forma idempotente
rm -rf /tmp/app
git clone https://github.com/josejuansanchez/iaw-practica-lamp.git /tmp/app

mariadb -e "DROP DATABASE IF EXISTS lamp_db; CREATE DATABASE lamp_db;"
mariadb lamp_db < /tmp/app/db/database.sql

# Crear usuario con privilegios mínimos restringido a Web1 y Web2
for NODO_WEB in "192.168.57.11" "192.168.57.12"; do
    mariadb -e "
        DROP USER IF EXISTS 'lamp_user'@'${NODO_WEB}';
        CREATE USER 'lamp_user'@'${NODO_WEB}' IDENTIFIED BY 'lamp_password';
        GRANT SELECT, INSERT, UPDATE, DELETE ON lamp_db.* TO 'lamp_user'@'${NODO_WEB}';
    "
done
mariadb -e "FLUSH PRIVILEGES;"
rm -rf /tmp/app

# Cortafuegos de Capa 3: permite SSH de gestión y MySQL (3306) solo desde Capa 2
IF_NAT=$(ip -o -4 route show to default | awk '{print $5}' | head -n1)
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow in on "$IF_NAT" to any port 22 proto tcp
ufw allow from 192.168.57.11 to any port 3306 proto tcp
ufw allow from 192.168.57.12 to any port 3306 proto tcp
sed -i "s/-p icmp --icmp-type echo-request -j ACCEPT/-p icmp --icmp-type echo-request -j DROP/" /etc/ufw/before.rules
ufw --force enable

# Aislar completamente de Internet
ip route del default || true