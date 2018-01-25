#!/bin/bash

# Default variables to be used in templates etc. These can be modified
maxbodysize="16M"
php5_fastcgipass="unix:/var/run/php5-fpm-portal.sock"
php7_fastcgipass=""
php5_ini_dir=""
php7_ini_dir=""
default_php_version=7
vhosts_root="/var/www/vhosts/"

# Stop editing at this point
usessl=true
pool_name=""
pool_max_children=16
pool_start_servers=6
pool_min_spare_servers=2
pool_max_spare_servers=6
pool_max_requests=500
pool_access_log="/var/log/$pool.access.log"
pool_user="www-data"
pool_group="www-data"

php_memory_limit="32M"
php_error_log_dir=""
php_max_body_size="16M"

nginx_error_log_dir=""

function reload_php {
	/etc/init.d/php-pfm reload
}

function create_vhost_conf_from_template {
	if [ $default_php_version = 7 ]; then
		fastcgipass=$php7_fastcgipass
	else
		fastcgipass=$php5_fastcgipass
	fi
	while IFS='' read -r line || [[ -n "$line" ]]; do
		line=${line/\[SERVERNAME\]/$server_name}
		line=${line/\[DOMAIN\]/$maindomain}
		line=${line/\[VHOSTROOT\]/\/var\/www\/vhosts\/$vhost\/httpdocs}
		line=${line/\[MAXBODYSIZE\]/$maxbodysize}
		line=${line/\[FASTCGIPASS\]/$fastcgipass}
		line=${line/\[MEMORYLIMIT\]/$php_memory_limit}
		line=${line/\[ERRORLOG\]/$nginx_error_log_dir}
	    echo "$line" | tee -a /etc/nginx/sites-enabled/$vhost.conf
	done < "/root/templates/$1"

	/etc/init.d/nginx reload
}

function create_pool_conf_from_template {
	while IFS='' read -r line || [[ -n "$line" ]]; do
		line=${line/\[POOLNAME\]/$pool_name}
		line=${line/\[MAXCHILDREN\]/$pool_max_children}
		line=${line/\[STARTSERVERS\]/$pool_start_servers}
		line=${line/\[MINSPARESERVERS\]/$pool_min_spare_servers}
		line=${line/\[MAXSPARESERVERS\]/$pool_max_spare_servers}
		line=${line/\[MAXREQUESTS\]/$pool_max_requests}
		line=${line/\[ACCESSLOG\]/$pool_access_log}
		line=${line/\[USER\]/$pool_user}
		line=${line/\[GROUP\]/$pool_group}
		line=${line/\[MEMORYLIMIT\]/$php_memory_limit}
		line=${line/\[ERRORLOG\]/$php_error_log_dir}
		line=${line/\[MAXBODYSIZE\]/$php_max_body_size}
	    echo "$line" | tee -a /etc/php5/fpm/pool.d/$pool_name.conf
	done < "/root/templates/pool.template.conf"
	php5_fastcgipass="unix:/var/run/php-fpm-[POOLNAME].sock"
	php7_fastcgipass="unix:/var/run/php-fpm-[POOLNAME].sock"
	reload_php;
}

function php_fpm_configuration {
	read -p "Set up own php pool? (Y/n): " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		read -p "Pool name: " pool_name

		read -p "pm.max_children (default: 16): " pool_max_children

		read -p "pm.start_servers (default: 6): " pool_start_servers

		read -p "pm.min_spare_servers (default: 2): " pool_min_spare_servers

		read -p "pm.max_spare_servers (default: 6): " pool_max_spare_servers

		read -p "pm.max_requests (default: 500): " pool_max_requests

		read -p "access.log (default: /var/log/$pool.access.log): " pool_access_log

		read -p "user (default: www-data): " pool_user

		read -p "group (default: www-data): " pool_group

 	fi
 	create_pool_conf_from_template;
}

function php_variables {
	read -p "Max body size (default: 16M): " php_max_body_size

	read -p "Log files directory: " php_error_log_dir

	read -p "Memory limit (default: 32M): " php_memory_limit
}

function advanced_setup {
	read -p "Advanced PHP configuration? (Y/n): " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		php_variables;
		php_fpm_configuration;
	fi
}

function ssl {
	read -p "Set up with SSL certificate? (Y/n): " -n 1 -r
	echo
	if [[ ! $REPLY =~ ^[Yy]$ ]]
	then
		usessl=false
	fi
	if $usessl; then

		echo "Setting up certificate"

		ssl_server_names=""

		for domain in $server_name
		do
			ssl_server_names="$ssl_server_names -d $domain"
		done

		sudo certbot certonly --webroot -w /var/www/vhosts/$vhost/httpdocs $ssl_server_names

		echo "Replacing nginx http config with https"

		sudo rm /etc/nginx/sites-enabled/$vhost.conf

		create_vhost_conf_from_template "https.template.conf"

	fi
}

function http {

	advanced_setup;

	echo "Creating nginx config (http)"

	create_vhost_conf_from_template "http.template.conf"

	ssl;
}

function create_dir {
	echo "Creating vhost directory"

	mkdir -v /var/www/vhosts/$vhost
	mkdir -v /var/www/vhosts/$vhost/httpdocs

	http;
}

function set_domain_info {
	echo "Enter the name of the vhosts"

	read vhost

	echo "Enter the main domain name"

	read maindomain

	echo "Enter the server name (space separated)"

	read server_name

	create_dir;
}

set_domain_info;
