#!/usr/bin/env bash
set -e
trap 'echo "Error on line $LINENO. Exiting." >&2' ERR

# Update system package list and upgrade installed packages
echo "=== Updating system packages ==="
sudo apt-get update -y
sudo apt-get upgrade -y

# Install required system packages and dependencies
echo "=== Installing system packages ==="
sudo apt-get install -y git python3-dev python3-setuptools python3-pip python3-venv build-essential \
                        mariadb-server libmysqlclient-dev redis-server nginx supervisor curl software-properties-common \
                        xvfb libfontconfig libxrender

# Create system user 'jhon' for running Bench commands if it doesn't exist
echo "=== Creating system user 'jhon' if not exists ==="
if id -u jhon >/dev/null 2>&1; then
    echo "User 'jhon' already exists"
else
    sudo adduser --disabled-password --gecos "" jhon
    sudo usermod -aG sudo jhon
    echo "User 'jhon' created"
fi

# Configure and secure MariaDB
echo "=== Configuring MariaDB ==="
sudo systemctl enable mariadb
sudo systemctl restart mariadb

# Create MariaDB user 'mariadb' with password 'admin' and grant privileges
USER_EXISTS=$(sudo mysql -u root -sse "SELECT EXISTS(SELECT 1 FROM mysql.user WHERE User='mariadb');")
if [ "$USER_EXISTS" = 0 ]; then
    sudo mysql -u root -e "CREATE USER 'mariadb'@'localhost' IDENTIFIED BY 'admin';"
    sudo mysql -u root -e "GRANT ALL PRIVILEGES ON *.* TO 'mariadb'@'localhost' WITH GRANT OPTION;"
    sudo mysql -u root -e "FLUSH PRIVILEGES;"
    echo "MariaDB user 'mariadb' created"
else
    echo "MariaDB user 'mariadb' already exists"
fi

# Configure MariaDB settings for Frappe/ERPNext (UTF8, InnoDB settings)
ERP_MARIADB_CONF="/etc/mysql/mariadb.conf.d/frappe.cnf"
if [ ! -f "$ERP_MARIADB_CONF" ]; then
    echo "Creating MariaDB configuration for ERPNext"
    sudo tee "$ERP_MARIADB_CONF" >/dev/null <<EOF
[mysqld]
innodb-file-format=barracuda
innodb-file-per-table=1
innodb-large-prefix=1
character-set-client-handshake = FALSE
character-set-server = utf8mb4
collation-server = utf8mb4_unicode_ci

[mysql]
default-character-set = utf8mb4
EOF
    sudo systemctl restart mariadb
    echo "MariaDB configuration updated"
else
    echo "MariaDB configuration already exists"
fi

# Install Node.js v18 using NodeSource
echo "=== Installing Node.js v18 ==="
if command -v node >/dev/null 2>&1; then
    NODE_VER=$(node -v)
else
    NODE_VER=""
fi
if [[ "$NODE_VER" != v18* ]]; then
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo "Node.js installed: $(node -v)"
else
    echo "Node.js $NODE_VER already installed"
fi

# Install Yarn package manager
echo "=== Installing Yarn ==="
if ! command -v yarn >/dev/null 2>&1; then
    curl -sL https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt-get update
    sudo apt-get install -y yarn
    echo "Yarn installed: $(yarn --version)"
else
    echo "Yarn already installed: $(yarn --version)"
fi

# Install wkhtmltopdf (Qt patched) and dependencies
echo "=== Installing wkhtmltopdf (patched) ==="
if ! dpkg -s libssl1.1 >/dev/null 2>&1; then
    echo "Installing libssl1.1 (required for wkhtmltopdf)"
    wget -q https://mirrors.sit.fraunhofer.de/ubuntu/pool/main/o/openssl/libssl1.1_1.1.1l-1ubuntu1.2_amd64.deb -O /tmp/libssl1.1.deb
    sudo dpkg -i /tmp/libssl1.1.deb
    sudo apt-get install -f -y
    rm -f /tmp/libssl1.1.deb
fi
if ! command -v wkhtmltopdf >/dev/null 2>&1; then
    echo "Downloading and installing wkhtmltopdf"
    wget -q https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.jammy_amd64.deb -O /tmp/wkhtmltox.deb
    sudo dpkg -i /tmp/wkhtmltox.deb
    sudo apt-get install -f -y
    rm -f /tmp/wkhtmltox.deb
    echo "wkhtmltopdf installed"
else
    echo "wkhtmltopdf already installed"
fi

# Install Bench CLI and Ansible via pip
echo "=== Installing Bench CLI and Ansible ==="
sudo -H pip3 install --upgrade pip
sudo -H pip3 install frappe-bench --break-system-packages
sudo -H pip3 install ansible --break-system-packages

# Initialize new Frappe Bench instance (as user 'jhon')
echo "=== Initializing Frappe Bench (frappe-bench) ==="
if [ ! -d "/home/jhon/frappe-bench" ]; then
    sudo -H -u jhon bash -c "bench init frappe-bench --frappe-branch version-15 --python /usr/bin/python3"
    echo "Bench initialized"
else
    echo "Bench directory already exists"
fi
sudo chmod -R o+rx /home/jhon

# Create a new ERPNext site named erp.local
echo "=== Creating ERPNext site 'erp.local' ==="
if [ ! -d "/home/jhon/frappe-bench/sites/erp.local" ]; then
    sudo -H -u jhon bash -c "cd /home/jhon/frappe-bench && bench new-site erp.local --mariadb-root-username mariadb --mariadb-root-password admin --admin-password erpadmin --db-type mariadb --verbose"
    echo "Site erp.local created"
else
    echo "Site erp.local already exists"
fi

# Download and install the ERPNext application
echo "=== Downloading ERPNext app ==="
if [ ! -d "/home/jhon/frappe-bench/apps/erpnext" ]; then
    sudo -H -u jhon bash -c "cd /home/jhon/frappe-bench && bench get-app erpnext --branch version-15"
    echo "ERPNext app downloaded"
else
    echo "ERPNext app already present"
fi

# Install the ERPNext app on the site
echo "=== Installing ERPNext app on erp.local ==="
sudo -H -u jhon bash -c "cd /home/jhon/frappe-bench && bench --site erp.local install-app erpnext"

# Enable scheduler and disable maintenance mode for the site
echo "=== Enabling scheduler and disabling maintenance mode ==="
sudo -H -u jhon bash -c "cd /home/jhon/frappe-bench && bench --site erp.local enable-scheduler"
sudo -H -u jhon bash -c "cd /home/jhon/frappe-bench && bench --site erp.local set-maintenance-mode off"

# Set up production environment (Supervisor and Nginx)
echo "=== Setting up production configuration (Supervisor + Nginx) ==="
sudo bench setup production jhon --yes

# Reload Supervisor configuration and restart services
echo "=== Reloading Supervisor and restarting Nginx ==="
sudo supervisorctl reread
sudo supervisorctl update
sudo supervisorctl restart all
sudo systemctl restart nginx

echo "=== ERPNext installation completed successfully! ==="
