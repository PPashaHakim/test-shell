#!/bin/bash
sudo apt-get update
sudo apt-get install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Install Node.js and PM2
curl -sL https://deb.nodesource.com/setup_14.x | sudo -E bash -
sudo apt-get install -y nodejs
sudo npm install -g pm2

# Create a sample Node.js app
cat <<EOF > /var/www/html/app.js
const express = require('express');
const app = express();
const port = 3000;  # Change the port to 3000

app.get('/', (req, res) => {
  res.send('Hello World!');
});

app.listen(port, () => {
  console.log(\`App running on port \${port}\`);
});
EOF

# Install dependencies and start the app with PM2
cd /var/www/html
npm install express
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
    proxy_pass http://localhost:3000;  # Proxy requests to the Node.js app
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
