Here is an alternative simple project that uses the database. This example creates a basic CRUD (Create, Read, Update, Delete) application for managing a list of items, such as a to-do list. 

```bash
#!/bin/bash

# Check for required parameters
if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <DB_SERVER> <DB_USER> <DB_PASSWORD> <DB_NAME>"
  exit 1
fi

DB_SERVER=$1
DB_USER=$2
DB_PASSWORD=$3
DB_NAME=$4

# Update package lists
sudo apt-get update

# Install Nginx
sudo apt-get install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx

# Install Node.js and PM2
curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
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

# Ensure the user's home directory exists
USER_HOME=$(eval echo ~$USER)
mkdir -p $USER_HOME

# Create the table in the SQL database
/opt/mssql-tools/bin/sqlcmd -S tcp:${DB_SERVER},1433 -U ${DB_USER} -P ${DB_PASSWORD} -d ${DB_NAME} -Q "IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'ToDoList') BEGIN CREATE TABLE ToDoList (ID INT PRIMARY KEY IDENTITY(1,1), Task NVARCHAR(100), Completed BIT); END"

# Create a sample Node.js app
sudo mkdir -p /var/www/html
cat <<EOF | sudo tee /var/www/html/app.js
const express = require('express');
const bodyParser = require('body-parser');
const app = express();
const sql = require('mssql');
const port = 3000;

app.use(bodyParser.json());

// SQL Server configuration
const config = {
  user: '${DB_USER}',
  password: '${DB_PASSWORD}',
  server: '${DB_SERVER}',
  database: '${DB_NAME}',
  options: {
    encrypt: true,
    trustServerCertificate: false,
    enableArithAbort: true,
  },
  port: 1433,
};

app.post('/tasks', async (req, res) => {
  try {
    await sql.connect(config);
    const { task } = req.body;
    await sql.query\`INSERT INTO ToDoList (Task, Completed) VALUES (\${task}, 0)\`;
    res.status(201).send('Task created');
  } catch (err) {
    console.error(err);
    res.status(500).send('Error creating task');
  }
});

app.get('/tasks', async (req, res) => {
  try {
    await sql.connect(config);
    const result = await sql.query\`SELECT * FROM ToDoList\`;
    res.json(result.recordset);
  } catch (err) {
    console.error(err);
    res.status(500).send('Error fetching tasks');
  }
});

app.put('/tasks/:id', async (req, res) => {
  try {
    await sql.connect(config);
    const { id } = req.params;
    const { task, completed } = req.body;
    await sql.query\`UPDATE ToDoList SET Task = \${task}, Completed = \${completed} WHERE ID = \${id}\`;
    res.send('Task updated');
  } catch (err) {
    console.error(err);
    res.status(500).send('Error updating task');
  }
});

app.delete('/tasks/:id', async (req, res) => {
  try {
    await sql.connect(config);
    const { id } = req.params;
    await sql.query\`DELETE FROM ToDoList WHERE ID = \${id}\`;
    res.send('Task deleted');
  } catch (err) {
    console.error(err);
    res.status(500).send('Error deleting task');
  }
});

app.listen(port, () => {
  console.log(\`App running on port \${port}\`);
});
EOF

# Install dependencies and start the app with PM2
cd /var/www/html
sudo npm install express body-parser mssql
sudo pm2 start /var/www/html/app.js
sudo pm2 startup systemd -u $USER --hp $USER_HOME
sudo pm2 save
sudo pm2 restart all

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

# Verify services
if ! pm2 list | grep -q 'app'; then
  echo "Starting Node.js application..."
  sudo pm2 start /var/www/html/app.js
else
  echo "Node.js application is already running."
fi

echo "Restarting Nginx..."
sudo systemctl restart nginx

# Check statuses
echo "Checking PM2 status..."
pm2 status

echo "Checking Nginx status..."
sudo systemctl status nginx
```
