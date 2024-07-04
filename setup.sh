#!/bin/bash

DB_HOST=$1
DB_USER=$2
DB_PASS=$3
DB_NAME=$4

sudo apt update && \
sudo apt -y install apache2 && \
sudo a2enmod rewrite && \
sudo systemctl restart apache2 && \
cd /var/www/html && \
sudo apt -y install php libapache2-mod-php && \
sudo apt -y install php-mysqli && \
sudo apt -y install git && \
sudo rm -f index.html && \
sudo git clone https://github.com/allistairhakim/simple-url-shortener.git . && \
sudo apt -y install mysql-server && \
sudo mv config.sample.php config.php && \
sudo sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf && \
sudo mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASS} ${DB_NAME} < database.sql | sudo tee output.log > /dev/null && \
sudo sed -i "s|\\\$dbhost = '';|\\\$dbhost = '${DB_HOST}';|; s|\\\$dbuser = '';|\\\$dbuser = '${DB_USER}';|; s|\\\$dbpass = '';|\\\$dbpass = '${DB_PASS}';|; s|\\\$dbname = '';|\\\$dbname = '${DB_NAME}';|" config.php && \
sudo systemctl restart apache2
