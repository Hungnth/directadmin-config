#!/bin/bash
# CHECK CUSTOM PKG ITEM INSTALLWP
if [[ $installWP != 'ON' ]]; then
  exit 0;
else

wpadmin="${cus_wp_user}"
wpadminpass=$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9!@#$%^&*()-_=+{}[]<>?') > /dev/null
dbname="${username}_${cus_db_name}"
dbuser="${username}_${cus_db_name}"
dbpass=$(openssl rand -base64 18 | tr -dc 'A-Za-z0-9!@#$%^&*()-_=+{}[]<>?') > /dev/null # Database password
WP_CLI_PATH="/usr/local/bin/wp"

# Move contents to backup folder
if [ "$(ls -A /home/$username/domains/$domain/public_html)" ]; then
mkdir -p /home/$username/wp-backup/$domain-backup
mv /home/$username/domains/$domain/public_html/* /home/$username/wp-backup/$domain-backup
chown -R $username. /home/$username/wp-backup
fi

# Create Dababase
/usr/bin/mysqladmin -uda_admin -p$(cat /usr/local/directadmin/conf/mysql.conf | grep pass | cut -d\= -f2) create ${dbname}

# Create MySQL user and grant full permissions to database
echo "CREATE USER '${dbuser}'@'localhost' IDENTIFIED BY '${dbpass}';" | mysql -uda_admin -p$(cat /usr/local/directadmin/conf/mysql.conf | grep pass | cut -d\= -f2)
echo "GRANT ALL PRIVILEGES ON ${dbname}.* TO '${dbuser}'@'localhost';" | mysql -uda_admin -p$(cat /usr/local/directadmin/conf/mysql.conf | grep pass | cut -d\= -f2)
echo "FLUSH PRIVILEGES;" | mysql -uda_admin -p$(cat /usr/local/directadmin/conf/mysql.conf | grep pass | cut -d\= -f2)

# Download Wordpress
cd /home/$username/domains/$domain/public_html/
su -s /bin/bash -c "${WP_CLI_PATH} core download" $username

# Set Database details in the config file
su -s /bin/bash -c "${WP_CLI_PATH} config create --dbname=${dbname} --dbuser=${dbuser} --dbpass=$dbpass --dbhost=localhost" $username
su -s /bin/bash -c "${WP_CLI_PATH} config set WP_MEMORY_LIMIT 256M" $username

# Install Wordpress
su -s /bin/bash -c "${WP_CLI_PATH} core install --url=https://$domain/ --admin_user=$wpadmin --admin_password=$wpadminpass --title=\"$domain\" --admin_email=$username@$domain " $username
su -s /bin/bash -c "${WP_CLI_PATH} rewrite structure '/%category%/%postname%-%post_id%/'" $username

if [[ ! -h /home/$username/domains/$domain/private_html ]]; then
  echo "Making a symlink for https..."
  cd /home/$username/domains/$domain/
  rm -rf private_html
  su -s /bin/bash -c "ln -s public_html private_html" $username
fi

cat << EOF > /home/$username/domains/$domain/public_html/.wp-details.txt
WORDPRESS LOGIN CREDENTIALS:
URL: https://$domain/wp-admin/
USERNAME: $wpadmin
PASSWORD: $wpadminpass
EOF
chown $username. /home/$username/domains/$domain/public_html/.wp-details.txt

# Delete default themes, plugins
su -s /bin/bash -c "${WP_CLI_PATH} theme delete twentytwentytwo" $username
su -s /bin/bash -c "${WP_CLI_PATH} theme delete twentytwentythree" $username
su -s /bin/bash -c "${WP_CLI_PATH} plugin delete hello" $username
su -s /bin/bash -c "${WP_CLI_PATH} plugin delete akismet" $username

# Options
# su -s /bin/bash -c "${WP_CLI_PATH} language core install vi_VN" $username
# su -s /bin/bash -c "${WP_CLI_PATH} site switch-language vi_VN" $username
# su -s /bin/bash -c "${WP_CLI_PATH} option update timezone_string 'Asia/Ho_Chi_Minh'" $username
# su -s /bin/bash -c "${WP_CLI_PATH} option update time_format 'H:i'" $username
# su -s /bin/bash -c "${WP_CLI_PATH} option update date_format 'd/m/Y'" $username
# su -s /bin/bash -c "${WP_CLI_PATH} option update large_size_w 0" $username
# su -s /bin/bash -c "${WP_CLI_PATH} option update large_size_h 0" $username
# su -s /bin/bash -c "${WP_CLI_PATH} option update medium_large_size_w 0" $username
# su -s /bin/bash -c "${WP_CLI_PATH} option update medium_large_size_h 0" $username
# su -s /bin/bash -c "${WP_CLI_PATH} option update medium_size_w 0" $username
# su -s /bin/bash -c "${WP_CLI_PATH} option update medium_size_h 0" $username
# su -s /bin/bash -c "${WP_CLI_PATH} option update thumbnail_size_w 0" $username
# su -s /bin/bash -c "${WP_CLI_PATH} option update thumbnail_size_h 0" $username
# su -s /bin/bash -c "${WP_CLI_PATH} option update thumbnail_crop 0" $username
# su -s /bin/bash -c "${WP_CLI_PATH} option update comment_moderation 1" $username
# su -s /bin/bash -c "${WP_CLI_PATH} option update default_pingback_flag 0" $username
# su -s /bin/bash -c "${WP_CLI_PATH} option update default_ping_status closed" $username

# Create .htaccess
cat << EOF > /home/$username/domains/$domain/public_html/.htaccess
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
chown $username. /home/$username/domains/$domain/public_html/.htaccess

# Change file permissions
cd /home/$username/domains/$domain/public_html/
find . -type d -exec chmod 0755 {} \;
find . -type f -exec chmod 0644 {} \;

# Wordpress security and hardening
chmod 400 /home/$username/domains/$domain/public_html/.wp-details.txt
chmod 400 /home/$username/domains/$domain/public_html/wp-config.php

printf -- "\n\n--------------------------------------------------"
printf "\n\nWORDPRESS LOGIN CREDENTIALS:\nURL: https://$domain/wp-admin/\nUSERNAME: $wpadmin\nPASSWORD: $wpadminpass\n\n"
printf -- "--------------------------------------------------\n\n"

fi
exit 0;
