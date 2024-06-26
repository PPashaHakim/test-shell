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
const port = 80;

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
