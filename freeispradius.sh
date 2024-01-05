#!/bin/bash

# Navigate to the web root
cd /var/www/html

# Clone the repository
sudo git clone https://github.com/Gomez1996/mikrotik

# Ask for the new folder name and move the cloned repository into it
read -p "Enter the new folder name: " foldername
sudo mv mikrotik $foldername

# Navigate into the new folder
cd /var/www/html/$foldername

# Rename the config file and set permissions
# Make sure the file 'config.sample.php' exists in the cloned repository
# If the file is not in the root of the repository, adjust the path accordingly
if [ -f config.sample.php ]; then
    sudo mv config.sample.php config.php
    sudo chmod -R 777 pages
    sudo chmod -R 777 config.php
else
    echo "config.sample.php does not exist in the current directory."
    exit 1
fi

# Navigate to the Apache sites-available directory
cd /etc/apache2/sites-available

# Use the folder name for the .conf file name
conffile=$foldername

# Create the .conf file with the necessary settings
echo "<VirtualHost *:443>
    ServerAdmin admin@example.com
    ServerName freeispradius.com
    ServerAlias www.$foldername.freeispradius.com

    DocumentRoot /var/www/html/$foldername

    <Directory /var/www/html/$foldername>
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>

    ErrorLog ${APACHE_LOG_DIR}/$foldername.freeispradius.com-error.log
    CustomLog ${APACHE_LOG_DIR}/$foldername.freeispradius.com-access.log combined

    Include /etc/letsencrypt/options-ssl-apache.conf
    ServerAlias $foldername.freeispradius.com
    SSLCertificateFile /etc/letsencrypt/live/demo.freeispradius.com/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/demo.freeispradius.com/privkey.pem
</VirtualHost>" | sudo tee $conffile.conf

# Enable the new site and restart Apache
sudo a2ensite $conffile.conf
sudo systemctl restart apache2

# Issue a new certificate
sudo certbot --apache -d $foldername.freeispradius.com

# Use the folder name for the MySQL username, password, and database name
username=$foldername
password=$foldername
dbname=$foldername

# Log into MySQL
mysql -u root -p <<EOF
CREATE USER '$username'@'localhost' IDENTIFIED BY '$password';
CREATE DATABASE $dbname;
GRANT ALL PRIVILEGES ON $dbname.* TO '$username'@'localhost';
FLUSH PRIVILEGES;
EOF

# Create a new directory and set permissions
sudo mkdir -p /var/www/html/$foldername/ui/compiled
sudo chown www-data:www-data /var/www/html/$foldername/ui/compiled
sudo chmod 755 /var/www/html/$foldername/ui/compiled
