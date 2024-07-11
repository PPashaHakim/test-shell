DB_HOST=$1
DB_USER=$2
DB_PASS=$3
DB_NAME=$4

# Update package list and install Apache2
sudo apt update && \
sudo apt -y install apache2 && \
sudo a2enmod rewrite && \
sudo systemctl restart apache2

# Navigate to web root and manually ensure it's empty
cd /var/www/html && \
sudo rm -rf * && \
sudo rm -rf .[!.]*

# Install PHP and required extensions
sudo apt -y install php libapache2-mod-php && \
sudo apt -y install php-mysqli

# Install Git and clone the repository
sudo apt -y install git && \
sudo git clone https://github.com/allistairhakim/simple-url-shortener.git . || exit 1

# Install MySQL server
sudo apt -y install mysql-server

# Configure the application
sudo mv config.sample.php config.php && \
sudo sed -i "s/AllowOverride None/AllowOverride All/g" /etc/apache2/apache2.conf && \
sudo mysql -h ${DB_HOST} -u ${DB_USER} -p${DB_PASS} ${DB_NAME} < database.sql | sudo tee output.log > /dev/null

# Update configuration file with database details
sudo sed -i "s|\\\$dbhost = '';|\\\$dbhost = '${DB_HOST}';|; s|\\\$dbuser = '';|\\\$dbuser = '${DB_USER}';|; s|\\\$dbpass = '';|\\\$dbpass = '${DB_PASS}';|; s|\\\$dbname = '';|\\\$dbname = '${DB_NAME}';|" config.php

# Restart Apache to apply changes
sudo systemctl restart apache2
