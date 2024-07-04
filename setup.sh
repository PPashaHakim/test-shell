      #!/bin/bash
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
      sudo mysql -h ${var.resource_prefix}.mysql.database.azure.com -u ${var.admin_username} -p${var.admin_password} ${var.resource_prefix}-mysqldb < database.sql | sudo tee output.log > /dev/null && \
      sudo sed -i "s|\\\$dbhost = '';|\\\$dbhost = '${var.resource_prefix}.mysql.database.azure.com';|; s|\\\$dbuser = '';|\\\$dbuser = '${var.admin_username}';|; s|\\\$dbpass = '';|\\\$dbpass = '${var.admin_password}';|; s|\\\$dbname = '';|\\\$dbname = '${var.resource_prefix}-mysqldb';|" config.php && \
      sudo systemctl restart apache2
