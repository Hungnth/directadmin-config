#!/bin/bash

# Ask the user to enter variables
read -p "Enter DirectAdmin username (e.g., admin | user_1): " da_username
read -p "Enter domain (e.g., domain.com): " domain
read -p "Enter database name (e.g., wp_1234): " ext
read -p "Enter WordPress admin username (e.g., wp-admin): " wpadmin
# Generate a random password for the WordPress admin
wpadminpass=$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9!@#$%^&*()-_=+{}[]<>?') > /dev/null

# Move contents to backup folder
if [ "$(ls -A /home/$da_username/domains/$domain/public_html)" ]; then
mkdir -p /home/$da_username/wp-backup/$domain-backup
mv /home/$da_username/domains/$domain/public_html/* /home/$da_username/wp-backup/$domain-backup
chown -R $da_username. /home/$da_username/wp-backup
fi

# Set up Database varibles
dbname="${da_username}_${ext}" # Database name
dbuser="${da_username}_${ext}" # Database user
dbpass=$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9!@#$%^&*()-_=+{}[]<>?') > /dev/null # Database pass
WP_CLI_PATH="/usr/local/bin/wp"

# Create Dababase
/usr/bin/mysqladmin -uda_admin -p$(cat /usr/local/directadmin/conf/mysql.conf | grep pass | cut -d\= -f2) create ${dbname}

# Create MySQL user and grant full permissions to database
echo "CREATE USER '${dbuser}'@'localhost' IDENTIFIED BY '${dbpass}';" | mysql -uda_admin -p$(cat /usr/local/directadmin/conf/mysql.conf | grep pass | cut -d\= -f2)
echo "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${dbuser}'@'localhost';" | mysql -uda_admin -p$(cat /usr/local/directadmin/conf/mysql.conf | grep pass | cut -d\= -f2)
echo "FLUSH PRIVILEGES;" | mysql -uda_admin -p$(cat /usr/local/directadmin/conf/mysql.conf | grep pass | cut -d\= -f2)

# Download Wordpress
cd /home/$da_username/domains/$domain/public_html/
su -s /bin/bash -c "${WP_CLI_PATH} core download --locale=vi_VN" $da_username

# Set Database details in the config file
su -s /bin/bash -c "${WP_CLI_PATH} config create --dbname=${dbname} --dbuser=${dbuser} --dbpass=$dbpass --dbhost=localhost" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} config set WP_MEMORY_LIMIT 256M" $da_username

# Install Wordpress
su -s /bin/bash -c "${WP_CLI_PATH} core install --url=https://$domain/ --admin_user=$wpadmin --admin_password=$wpadminpass --title=\"$domain\" --admin_email=$da_username@$domain " $da_username

su -s /bin/bash -c "${WP_CLI_PATH} rewrite structure '/%category%/%postname%-%post_id%/'" $da_username

if [[ ! -h /home/$da_username/domains/$domain/private_html ]]; then
  echo "Making a symlink for https..."
  cd /home/$da_username/domains/$domain/
  rm -rf private_html
  su -s /bin/bash -c "ln -s public_html private_html" $da_username
fi

cat << EOF > /home/$da_username/domains/$domain/public_html/.wp-details.txt
WORDPRESS LOGIN CREDENTIALS:
USERNAME: $wpadmin
URL: https://$domain/wp-admin/
PASSWORD: $wpadminpass
EOF
chown $da_username. /home/$da_username/domains/$domain/public_html/.wp-details.txt

# Delete default themes, plugins
su -s /bin/bash -c "${WP_CLI_PATH} theme delete twentytwentytwo" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} theme delete twentytwentythree" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} plugin delete hello" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} plugin delete akismet" $da_username

# Install Theme, add flag '--active' to active plugin after install
echo "Install theme Flatsome"
su -s /bin/bash -c "${WP_CLI_PATH} theme install 'https://' --activate" $da_username # Flatsome
su -s /bin/bash -c "${WP_CLI_PATH} theme delete twentytwentyfour" $da_username #

# Install Plugins, add flag '--active' to active plugin after install
echo "Install plugin Rank Math SEO Free"
su -s /bin/bash -c "${WP_CLI_PATH} plugin install seo-by-rank-math" $da_username # Rank Math SEO
echo "Install plugin Rank Math SEO Pro"
su -s /bin/bash -c "${WP_CLI_PATH} plugin install 'https://'" $da_username # Rank Math SEO Pro

# Options
su -s /bin/bash -c "${WP_CLI_PATH} language core install vi" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} site switch-language vi" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} option update timezone_string 'Asia/Ho_Chi_Minh'" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} option update time_format 'H:i'" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} option update date_format 'd/m/Y'" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} option update large_size_w 0" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} option update large_size_h 0" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} option update medium_large_size_w 0" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} option update medium_large_size_h 0" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} option update medium_size_w 0" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} option update medium_size_h 0" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} option update thumbnail_size_w 0" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} option update thumbnail_size_h 0" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} option update thumbnail_crop 0" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} option update comment_moderation 1" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} option update default_pingback_flag 0" $da_username
su -s /bin/bash -c "${WP_CLI_PATH} option update default_ping_status closed" $da_username

# Create .htaccess
cat << EOF > /home/$da_username/domains/$domain/public_html/.htaccess
# BEGIN WordPress
RewriteEngine On
RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
RewriteBase /
RewriteRule ^index\.php$ - [L]
RewriteCond %{REQUEST_FILENAME} !-f
RewriteCond %{REQUEST_FILENAME} !-d
RewriteRule . /index.php [L]
# END WordPress
EOF
chown $da_username. /home/$da_username/domains/$domain/public_html/.htaccess

# Change file permissions
cd /home/$da_username/domains/$domain/public_html/
find . -type d -exec chmod 0755 {} \;
find . -type f -exec chmod 0644 {} \;

# Wordpress security and hardening
chmod 400 /home/$da_username/domains/$domain/public_html/.wp-details.txt
chmod 400 /home/$da_username/domains/$domain/public_html/wp-config.php

printf -- "\n\n--------------------------------------------------"
printf "\n\nWORDPRESS LOGIN CREDENTIALS:\nURL: https://$domain/wp-admin/\nUSERNAME: $wpadmin\nPASSWORD: $wpadminpass\n\n"
printf -- "--------------------------------------------------\n\n"

exit 0;
