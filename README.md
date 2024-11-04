# Auto install Wordpress on Directadmin

## Add Wordpress Package to Directadmin

```bash
wget --no-check-certificate -O add-install-wp-package.sh "https://raw.githubusercontent.com/Hungnth/directadmin-config/main/auto-install-wordpress/add-install-wp-package.sh"
chmod +x add-install-wp-package.sh
./add-install-wp-package.sh
```

## Auto install and configure Wordpress on Directadmin

```bash
curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar
chmod +x wp-cli.phar
sudo mv wp-cli.phar /usr/local/bin/wp
wget --no-check-certificate -O install-wp.sh "https://raw.githubusercontent.com/Hungnth/directadmin-config/main/install-wp.sh"
chmod +x install-wp.sh
./install-wp.sh
```