#!/bin/bash

rm -rf /usr/local/directadmin/data/admin/custom_package_items.conf
rm -rf /usr/local/directadmin/data/admin/custom_domain_items.conf
rm -rf /usr/local/directadmin/scripts/custom/user_create_post.sh
rm -rf /usr/local/directadmin/scripts/custom/domain_create_post.sh
rm -rf /usr/local/directadmin/scripts/custom/domain_modify_post.sh
rm -rf /usr/local/directadmin/scripts/custom/subdomain_create_post.sh
cd /usr/local/directadmin/data/admin
wget --no-check-certificate "https://raw.githubusercontent.com/Hungnth/directadmin-config/main/auto-install-wordpress/custom_package_items.conf" -O custom_package_items.conf
chown diradmin. custom_package_items.conf
chmod 700 custom_package_items.conf
wget --no-check-certificate "https://raw.githubusercontent.com/Hungnth/directadmin-config/main/auto-install-wordpress/custom_domain_items.conf" -O custom_domain_items.conf
chown diradmin. custom_domain_items.conf
chmod 700 custom_domain_items.conf
cd /usr/local/directadmin/scripts/custom
wget --no-check-certificate "https://raw.githubusercontent.com/Hungnth/directadmin-config/main/auto-install-wordpress/user_create_post.sh" -O user_create_post.sh
chown diradmin.diradmin user_create_post.sh
chmod 700 user_create_post.sh
wget --no-check-certificate "https://raw.githubusercontent.com/Hungnth/directadmin-config/main/auto-install-wordpress/domain_create_post.sh" -O domain_create_post.sh
chown diradmin.diradmin domain_create_post.sh
chmod 700 domain_create_post.sh
wget --no-check-certificate "https://raw.githubusercontent.com/Hungnth/directadmin-config/main/auto-install-wordpress/domain_modify_post.sh" -O domain_modify_post.sh
chown diradmin.diradmin domain_modify_post.sh
chmod 700 domain_modify_post.sh
wget --no-check-certificate "https://raw.githubusercontent.com/Hungnth/directadmin-config/main/auto-install-wordpress/subdomain_create_post.sh" -O subdomain_create_post.sh
chown diradmin.diradmin subdomain_create_post.sh
chmod 700 subdomain_create_post.sh
systemctl restart directadmin

