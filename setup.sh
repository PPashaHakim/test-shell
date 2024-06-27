#!/bin/bash

# Update package lists
sudo apt-get update

# Install Nginx
sudo apt-get install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Install Node.js and PM2
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g pm2

# Install SQL Server tools
curl https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add -
curl https://packages.microsoft.com/config/ubuntu/$(lsb_release -rs)/prod.list | sudo tee /etc/apt/sources.list.d/msprod.list
sudo apt-get update
sudo apt-get install -y mssql-tools unixodbc-dev
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile
echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc
source ~/.bashrc

# Create the table in the SQL database
/opt/mssql-tools/bin/sqlcmd -S allistair-sqlserver.database.windows.net -U adminuser -P Admin123456! -d allistair-sqldb -Q "CREATE TABLE AccessCount (ID INT PRIMARY KEY, Count INT); INSERT INTO AccessCount (ID, Count) VALUES (1, 0);"

# Create a sample Node.js app
cat <<EOF > /var/www/html/app.js
const express = require('express');
const app = express();
const sql = require('mssql');
const port = 3000;

// SQL Server configuration
const config = {
  user: 'adminuser',
  password: 'Admin123456!',
  server: 'allistair-sqlserver.database.windows.net',
  database: 'allistair-sqldb',
  options: {
    encrypt: true,
  },
};

app.get('/', async (req, res) => {
  try {
    await sql.connect(config);
    const result = await sql.query\`SELECT Count FROM AccessCount WHERE ID = 1\`;
    let count = result.recordset[0].Count;

    // Increment the count
    count += 1;
    await sql.query\`UPDATE AccessCount SET Count = \${count} WHERE ID = 1\`;

    res.send(\`Hello World! This page has been accessed \${count} times.\`);
  } catch (err) {
    console.error(err);
    res.status(500).send('Error accessing the database');
  }
});

app.listen(port, () => {
  console.log(\`App running on port \${port}\`);
});
EOF

# Install dependencies and start the app with PM2
cd /var/www/html
npm install express mssql
pm2 start app.js
pm2 startup systemd
pm2 save
pm2 restart all

# Configure Nginx to proxy requests to the Node.js application
cat <<EOF | sudo tee /etc/nginx/sites-available/default
server {
  listen 80;

  server_name _;

  location / {
    proxy_pass http://localhost:3000;
    proxy_http_version 1.1;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection 'upgrade';
    proxy_set_header Host \$host;
    proxy_cache_bypass \$http_upgrade;
  }
}
EOF

# Restart Nginx to apply the new configuration
sudo systemctl restart nginx
