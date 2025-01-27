#!/bin/bash

# Ask for the domain name
read -p "Enter the domain name for your WordPress site: " domain

# Ask for database-related variables
read -p "Enter the database name: " databasename
read -p "Enter the database user: " databaseuser
read -s -p "Enter the database password: " dbpassword
echo
read -p "Enter the database host IP address (usually 'localhost'): " databasehost

echo "Updating package lists..."
sudo apt update

echo "Installing Apache..."
sudo apt install -y apache2

echo "Allowing Apache through the firewall..."
sudo ufw allow 'Apache Full'
sudo ufw reload

echo "Installing PHP and necessary extensions..."
sudo apt install -y php php-mysql php-gd php-curl php-mbstring php-xmlrpc php-xml php-soap php-zip php-intl mysql-server

echo "Downloading WordPress..."
curl -O https://wordpress.org/latest.tar.gz

echo "Creating directory /var/www/$domain/..."
sudo mkdir -p /var/www/$domain/

echo "Extracting WordPress archive to /var/www/$domain/..."
sudo tar xf latest.tar.gz -C /var/www/$domain/

echo "Changing ownership of WordPress files..."
sudo chown -R www-data:www-data /var/www/$domain/

# Create the virtual host configuration file
sudo tee /etc/apache2/sites-available/$domain.conf > /dev/null <<EOF
<VirtualHost *:80>
    ServerAdmin webmaster@example.com
    ServerName $domain
    ServerAlias www.$domain

    DocumentRoot /var/www/$domain/wordpress

    <Directory /var/www/$domain/wordpress>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog \${APACHE_LOG_DIR}/$domain_error.log
    CustomLog \${APACHE_LOG_DIR}/$domain_access.log combined

</VirtualHost>
EOF

echo "Virtual host configuration file created at /etc/apache2/sites-available/"

echo "Enabling the WordPress site..."
sudo a2ensite $domain

echo "Disabling the default site..."
sudo a2dissite 000-default

echo "Creating MySQL database and user..."

# Execute MySQL commands using Bash variable substitution
sudo mysql -u root -p -e "
CREATE DATABASE IF NOT EXISTS \`$databasename\`;
CREATE USER IF NOT EXISTS '$databaseuser'@'%' IDENTIFIED BY '$dbpassword';
GRANT ALL PRIVILEGES ON \`$databasename\`.* TO '$databaseuser'@'%';
FLUSH PRIVILEGES;
"

echo "Database '$databasename' and user '$databaseuser' created with necessary privileges."



echo "Renaming WordPress configuration file..."
sudo mv /var/www/$domain/wordpress/wp-config-sample.php /var/www/$domain/wordpress/wp-config.php

# Modify the wp-config.php file with the provided variables
sudo sed -i "s/define( 'DB_NAME', 'database_name_here' );/define( 'DB_NAME', '$databasename' );/" /var/www/$domain/wordpress/wp-config.php
sudo sed -i "s/define( 'DB_USER', 'username_here' );/define( 'DB_USER', '$databaseuser' );/" /var/www/$domain/wordpress/wp-config.php
sudo sed -i "s/define( 'DB_PASSWORD', 'password_here' );/define( 'DB_PASSWORD', '$dbpassword' );/" /var/www/$domain/wordpress/wp-config.php
sudo sed -i "s/define( 'DB_HOST', 'localhost' );/define( 'DB_HOST', '$databasehost' );/" /var/www/$domain/wordpress/wp-config.php

echo "WordPress configuration updated with database variables."

echo "Restarting Apache..."
sudo systemctl restart apache2

echo "WordPress installation and configuration complete."


