#!/bin/bash
#
# provision.sh
#
# This file is specified in Vagrantfile and is loaded by Vagrant as the primary
# provisioning script whenever the commands `vagrant up`, `vagrant provision`,
# or `vagrant reload` are used. It provides all of the default packages and
# configurations included with Varying Vagrant Vagrants.

# By storing the date now, we can calculate the duration of provisioning at the end of this script.
start_seconds="$(date +%s)"

# PACKAGE INSTALLATION
#
# Build a bash array to pass all of the packages we want to install to a single
# apt-get command. This avoids doing all the leg work each time a package is
# set to install. It also allows us to easily comment out or add single
# packages. We set the array as empty to begin with so that we can append
# individual packages to it as required.
apt_package_install_list=()

# Start with a bash array containing all packages we want to install in the
# virtual machine. We'll then loop through each of these and check individual
# status before adding them to the apt_package_install_list array.
apt_package_check_list=(

  # PHP
  # Our base packages for php7.0. As long as php7.0-fpm and php7.0-cli are installed, there is no need to install the general php7.0 package, which can sometimes install apache as a requirement.
  php7.0-fpm
  php7.0-cli

  # Common and dev packages for php
  php7.0-common
  php7.0-dev

  # Extra PHP modules that we find useful
  php-memcache
  php-imagick
  php7.0-mbstring
  php7.0-mcrypt
  php7.0-mysql
  php7.0-imap
  php7.0-curl
  php-pear
  php7.0-gd

  # nginx is installed as the default web server
  nginx

  # memcached is made available for object caching
  memcached

  # mysql is the default database
  mysql-server

  # other packages that come in handy
  imagemagick
  git-core
  zip
  unzip
  ngrep
  curl
  make
  #colordiff
  postfix

  # ntp service to keep clock current
  ntp

  # Req'd for i18n tools
  gettext

  # Req'd for Webgrind
  graphviz

  # Allows conversion of DOS style line endings to something we'll have less trouble with in Linux.
  dos2unix

  # nodejs for use by grunt
  g++
  nodejs

  # Mailcatcher requirement
  libsqlite3-dev

)

### FUNCTIONS

network_detection() {
  # Make an HTTP request to google.com to determine if outside access is available to us. If 3 attempts with a timeout of 5 seconds are not successful, then we'll skip a few things further in provisioning rather than create a bunch of errors.
  if [[ "$(wget --tries=3 --timeout=5 --spider http://google.com 2>&1 | grep 'connected')" ]]; then
    ping_result="Connected"
  else
    echo "Network connection not detected. Unable to reach google.com..."
    ping_result="Not Connected"
  fi
}

network_check() {
  network_detection
  if [[ ! "$ping_result" == "Connected" ]]; then
    echo -e "\nNo network connection available, skipping package installation"
    exit 0
  fi
}

noroot() {
  sudo -EH -u "vagrant" "$@";
}

profile_setup() {
  # Copy custom dotfiles and bin file for the vagrant user from local
  cp "/srv/config/bash_profile" "/home/vagrant/.bash_profile"
  cp "/srv/config/bash_aliases" "/home/vagrant/.bash_aliases"
  cp "/srv/config/vimrc" "/home/vagrant/.vimrc"

  if [[ ! -d "/home/vagrant/bin" ]]; then
    mkdir "/home/vagrant/bin"
  fi

  rsync -rvzh --delete "/srv/config/homebin/" "/home/vagrant/bin/"

  # If a bash_prompt file exists in the VVV config/ directory, copy to the VM.
  if [[ -f "/srv/config/bash_prompt" ]]; then
    cp "/srv/config/bash_prompt" "/home/vagrant/.bash_prompt"
  fi
}

not_installed() {
   if [[ "$(dpkg -s ${1} 2>&1 | grep 'Version:')" ]]; then
      [[ -n "$(apt-cache policy ${1} | grep 'Installed: (none)')" ]] && return 0 || return 1
   else
      return 0
   fi
}

package_check() {
  # Loop through each of our packages that should be installed on the system. If not yet installed, it should be added to the array of packages to install.
  local pkg
  local package_version

  for pkg in "${apt_package_check_list[@]}"; do
    if not_installed "${pkg}"; then
      echo " *" $pkg [not installed]
      apt_package_install_list+=($pkg)
    else
      package_version=$(dpkg -s "${pkg}" 2>&1 | grep 'Version:' | cut -d " " -f 2)
      space_count="$(expr 20 - "${#pkg}")" #11
      pack_space_count="$(expr 30 - "${#package_version}")"
      real_space="$(expr ${space_count} + ${pack_space_count} + ${#package_version})"
      printf " * $pkg %${real_space}.${#package_version}s ${package_version}\n"
    fi
  done
}

package_install() {
  package_check

  # MySQL
  #
  # Use debconf-set-selections to specify the default password for the root MySQL account. This runs on every provision, even if MySQL has been installed. If MySQL is already installed, it will not affect anything.
  echo mysql-server mysql-server/root_password password "root" | debconf-set-selections
  echo mysql-server mysql-server/root_password_again password "root" | debconf-set-selections

  # Postfix
  #
  # Use debconf-set-selections to specify the selections in the postfix setup. Set up as an 'Internet Site' with the host name 'vvv'. Note that if your current Internet connection does not allow communication over port 25, you will not be able to send mail, even with postfix installed.
  echo postfix postfix/main_mailer_type select Internet Site | debconf-set-selections
  echo postfix postfix/mailname string vvv | debconf-set-selections

  # Disable ipv6 as some ISPs/mail servers have problems with it
  echo "inet_protocols = ipv4" >> "/etc/postfix/main.cf"

  # Provide our custom apt sources before running `apt-get update`
  ln -sf /srv/config/apt-source-append.list /etc/apt/sources.list.d/vvv-sources.list
  echo "Linked custom apt sources"

  if [[ ${#apt_package_install_list[@]} > 0 ]]; then
    # Before running `apt-get update`, we should add the public keys for the packages that we are installing from non standard sources via our appended apt source.list

    # Retrieve the Nginx signing key from nginx.org
    wget --quiet "http://nginx.org/keys/nginx_signing.key" -O- | apt-key add -

    # Apply the nodejs signing key
    apt-key adv --quiet --keyserver "hkp://keyserver.ubuntu.com:80" --recv-key C7917B12 2>&1 | grep "gpg:"
    apt-key export C7917B12 | apt-key add -

    # Apply the PHP signing key
    apt-key adv --quiet --keyserver "hkp://keyserver.ubuntu.com:80" --recv-key E5267A6C 2>&1 | grep "gpg:"
    apt-key export E5267A6C | apt-key add -

    # Update all of the package references before installing anything
    echo "Running apt-get update..."
    apt-get -y update

    # Install required packages
    echo "Installing apt-get packages..."
    apt-get -y install ${apt_package_install_list[@]}

    # Remove unnecessary packages
    echo "Removing unnecessary packages..."
    apt-get autoremove -y

    # Clean up apt caches
    apt-get clean
  fi
}

tools_install() {
  # npm
  #
  # Make sure we have the latest npm version and the update checker module
  npm install -g npm
  npm install -g npm-check-updates

  # Xdebug
  #
  # The version of Xdebug 2.4.0 that is available for our Ubuntu installation is not compatible with PHP 7.0. We instead retrieve the source package and go through the manual installation steps.
  if [[ -f /usr/lib/php/20151012/xdebug.so ]]; then
      echo "Xdebug already installed"
  else
      echo "Installing Xdebug"
      # Download and extract Xdebug.
      curl -L -O --silent https://xdebug.org/files/xdebug-2.4.0.tgz
      tar -xf xdebug-2.4.0.tgz
      cd xdebug-2.4.0
      # Create a build environment for Xdebug based on our PHP configuration.
      phpize
      # Complete configuration of the Xdebug build.
      ./configure -q
      # Build the Xdebug module for use with PHP.
      make -s > /dev/null
      # Install the module.
      cp modules/xdebug.so /usr/lib/php/20151012/xdebug.so
      # Clean up.
      cd ..
      rm -rf xdebug-2.4.0*
      echo "Xdebug installed"
  fi

  # ack-grep
  #
  # Install ack-rep directory from the version hosted at beyondgrep.com as the PPAs for Ubuntu Precise are not available yet.
  if [[ ! -f /usr/bin/ack ]]; then
    echo "Installing ack-grep as ack"
    curl -s http://beyondgrep.com/ack-2.14-single-file > "/usr/bin/ack" && chmod +x "/usr/bin/ack"
  fi

  # COMPOSER
  #
  # Install Composer if it is not yet available.
  if [[ ! -n "$(composer --version --no-ansi | grep 'Composer version')" ]]; then
    echo "Installing Composer..."
    curl -sS "https://getcomposer.org/installer" | php
    chmod +x "composer.phar"
    mv "composer.phar" "/usr/local/bin/composer"
  fi

  if [[ -f /vagrant/provision/github.token ]]; then
    ghtoken=`cat /vagrant/provision/github.token`
    composer config --global github-oauth.github.com $ghtoken
    echo "Your personal GitHub token is set for Composer."
  fi

  # Update both Composer and any global packages. Updates to Composer are direct from the master branch on its GitHub repository.
  if [[ -n "$(composer --version --no-ansi | grep 'Composer version')" ]]; then
    echo "Updating Composer..."
    COMPOSER_HOME=/usr/local/src/composer composer self-update
    COMPOSER_HOME=/usr/local/src/composer composer -q global require --no-update phpunit/phpunit:4.8.*
    COMPOSER_HOME=/usr/local/src/composer composer -q global require --no-update phpunit/php-invoker:1.1.*
    COMPOSER_HOME=/usr/local/src/composer composer -q global require --no-update mockery/mockery:0.9.*
    COMPOSER_HOME=/usr/local/src/composer composer -q global require --no-update d11wtq/boris:v1.0.8
    COMPOSER_HOME=/usr/local/src/composer composer -q global config bin-dir /usr/local/bin
    COMPOSER_HOME=/usr/local/src/composer composer global update
  fi

  # Grunt
  #
  # Install or Update Grunt based on current state.  Updates are direct
  # from NPM
#  if [[ ! "$(grunt --version)" ]]; then
#    echo "Updating Grunt CLI"
#    npm update -g grunt-cli &>/dev/null
#    npm update -g grunt-sass &>/dev/null
#    npm update -g grunt-cssjanus &>/dev/null
#    npm update -g grunt-rtlcss &>/dev/null
# fi
  if [[ ! "$(grunt --version)" ]]; then
    echo "Installing Grunt CLI"
    npm install -g grunt-cli &>/dev/null
    npm install -g grunt-sass &>/dev/null
    npm install -g grunt-cssjanus &>/dev/null
    npm install -g grunt-rtlcss &>/dev/null
  fi

  # Graphviz
  #
  # Set up a symlink between the Graphviz path defined in the default Webgrind config and actual path.
  echo "Adding graphviz symlink for Webgrind..."
  ln -sf "/usr/bin/dot" "/usr/local/bin/dot"
}

nginx_setup() {

  # Create an SSL key and certificate for HTTPS support.
  if [[ ! -e /etc/nginx/server.key ]]; then
	  echo "Generating Nginx server private key..."
	  vvvgenrsa="$(openssl genrsa -out /etc/nginx/server.key 2048 2>&1)"
#	  echo "$vvvgenrsa"
  fi
  if [[ ! -e /etc/nginx/server.crt ]]; then
	  echo "Signing the certificate using the above private key..."
	  vvvsigncert="$(openssl req -new -x509 \
            -key /etc/nginx/server.key \
            -out /etc/nginx/server.crt \
            -days 3650 \
            -subj /CN=*.*.dev 2>&1)"
#	  echo "$vvvsigncert"
  fi

  echo -e "\nSetup configuration files..."

  # Used to ensure proper services are started on `vagrant up`
  cp "/srv/config/init/vvv-start.conf" "/etc/init/vvv-start.conf"

  # Copy nginx configuration from local
  cp "/srv/config/nginx-config/nginx.conf" "/etc/nginx/nginx.conf"
  cp "/srv/config/nginx-config/nginx-wp-common.conf" "/etc/nginx/nginx-wp-common.conf"
  if [[ ! -d "/etc/nginx/custom-sites" ]]; then
    mkdir "/etc/nginx/custom-sites/"
  fi
  rsync -rvzh --delete "/srv/config/nginx-config/sites/" "/etc/nginx/custom-sites/"
}

phpfpm_setup() {
  # Copy php-fpm configuration from local
  cp "/srv/config/php-config/php7-fpm.conf" "/etc/php/7.0/fpm/php-fpm.conf"
  cp "/srv/config/php-config/www.conf" "/etc/php/7.0/fpm/pool.d/www.conf"
  cp "/srv/config/php-config/php-custom.ini" "/etc/php/7.0/fpm/conf.d/php-custom.ini"
  cp "/srv/config/php-config/opcache.ini" "/etc/php/7.0/fpm/conf.d/opcache.ini"
  cp "/srv/config/php-config/xdebug.ini" "/etc/php/7.0/mods-available/xdebug.ini"

  # Find the path to Xdebug and prepend it to xdebug.ini
  XDEBUG_PATH=$( find /usr/lib/php/ -name 'xdebug.so' | head -1 )
  sed -i "1izend_extension=\"$XDEBUG_PATH\"" "/etc/php/7.0/mods-available/xdebug.ini"

  # Copy memcached configuration from local
  cp "/srv/config/memcached-config/memcached.conf" "/etc/memcached.conf"
}

mysql_setup() {
  # If MySQL is installed, go through the various imports and service tasks.
  local exists_mysql

  exists_mysql="$(service mysql status)"
  if [[ "mysql: unrecognized service" != "${exists_mysql}" ]]; then
#    echo -e "\nSetup MySQL configuration file links..."

    # Copy mysql configuration from local
    cp "/srv/config/mysql-config/my.cnf" "/etc/mysql/my.cnf"
    cp "/srv/config/mysql-config/root-my.cnf" "/home/vagrant/.my.cnf"

    # MySQL gives us an error if we restart a non running service, which happens after a `vagrant halt`. Check to see if it's running before deciding whether to start or restart.
    if [[ "mysql stop/waiting" == "${exists_mysql}" ]]; then
      echo "service mysql start"
      service mysql start
    else
      echo "service mysql restart"
      service mysql restart
    fi

    # IMPORT SQL
    #
    # Setup MySQL by importing an init file that creates necessary users and databases that our vagrant setup relies on.
    mysql -u "root" -p"root" < "/srv/database/init.sql"
    echo "Initial MySQL prep..."

    # Process each mysqldump SQL file in database/backups to import an initial data set for MySQL.
	/srv/config/homebin/db_import_overwrite
  else
    echo -e "\nMySQL is not installed. No databases imported."
  fi
}

mailcatcher_setup() {
  # Mailcatcher
  #
  # Installs mailcatcher using RVM. RVM allows us to install the current version of ruby and all mailcatcher dependencies reliably.
  local pkg

  rvm_version="$(/usr/bin/env rvm --silent --version 2>&1 | grep 'rvm ' | cut -d " " -f 2)"
  if [[ -n "${rvm_version}" ]]; then
    pkg="RVM"
#    space_count="$(( 20 - ${#pkg}))" #11
#    pack_space_count="$(( 30 - ${#rvm_version}))"
#    real_space="$(( ${space_count} + ${pack_space_count} + ${#rvm_version}))"
#    printf " * $pkg %${real_space}.${#rvm_version}s ${rvm_version}\n"
  else
    # RVM key D39DC0E3
    # Signatures introduced in 1.26.0
    gpg -q --no-tty --batch --keyserver "hkp://keyserver.ubuntu.com:80" --recv-keys D39DC0E3
    gpg -q --no-tty --batch --keyserver "hkp://keyserver.ubuntu.com:80" --recv-keys BF04FF17

    printf " * RVM [not installed]\n Installing from source"
    curl --silent -L "https://get.rvm.io" | sudo bash -s stable --ruby
    source "/usr/local/rvm/scripts/rvm"
  fi

  mailcatcher_version="$(/usr/bin/env mailcatcher --version 2>&1 | grep 'mailcatcher ' | cut -d " " -f 2)"
  if [[ -n "${mailcatcher_version}" ]]; then
    pkg="Mailcatcher"
#    space_count="$(( 20 - ${#pkg}))" #11
#    pack_space_count="$(( 30 - ${#mailcatcher_version}))"
#    real_space="$(( ${space_count} + ${pack_space_count} + ${#mailcatcher_version}))"
#    printf " * $pkg %${real_space}.${#mailcatcher_version}s ${mailcatcher_version}\n"
  else
    echo " * Mailcatcher [not installed]"
    /usr/bin/env rvm default@mailcatcher --create do gem install mailcatcher --no-rdoc --no-ri
    /usr/bin/env rvm wrapper default@mailcatcher --no-prefix mailcatcher catchmail
  fi

  if [[ ! -f "/etc/init/mailcatcher.conf" ]]; then
    cp "/srv/config/init/mailcatcher.conf"  "/etc/init/mailcatcher.conf"
  fi

  if [[ ! -f "/etc/php/7.0/mods-available/mailcatcher.ini" ]]; then
    cp "/srv/config/php-config/mailcatcher.ini" "/etc/php/7.0/mods-available/mailcatcher.ini"
  fi
}

services_restart() {
	# RESTART SERVICES
	# Make sure the services we expect to be running are running.
	echo -e "\nRestarting services..."
	service nginx restart
	service memcached restart
	service mailcatcher restart

	# Disable PHP Xdebug module by default
	phpdismod xdebug

	# Enable PHP mcrypt module by default
	phpenmod mcrypt

	# Enable PHP mailcatcher sendmail settings by default
	phpenmod mailcatcher

	service php7.0-fpm restart

	# Add the vagrant user to the www-data group so that it has better access to PHP and Nginx related files.
	usermod -a -G www-data vagrant
}

wp_cli() {
	# Install
	if [[ ! -d "/srv/www/wp-cli" ]]; then
		echo -e "\nDownloading wp-cli, see http://wp-cli.org"
		git clone "https://github.com/wp-cli/wp-cli.git" "/srv/www/wp-cli"
		cd /srv/www/wp-cli
		composer install
	# Update
	else
		echo -e "\nUpdating wp-cli..."
		cd /srv/www/wp-cli
		git reset --hard
		git pull --rebase origin master
		composer update
	fi
	# Link `wp` to the `/usr/local/bin` directory
	ln -sf "/srv/www/wp-cli/bin/wp" "/usr/local/bin/wp"
}

# Download and extract phpMemcachedAdmin to provide a dashboard view and admin interface to the goings on of memcached when running
memcached_admin() {
	if [[ ! -d "/srv/www/default/memcached-admin" ]]; then
		echo -e "\nDownloading phpMemcachedAdmin, see https://github.com/wp-cloud/phpmemcacheadmin"
		cd /srv/www/default
		wget -q -O phpmemcachedadmin.tar.gz "https://github.com/wp-cloud/phpmemcacheadmin/archive/1.2.2.1.tar.gz"
		tar -xf phpmemcachedadmin.tar.gz
		mv phpmemcacheadmin* memcached-admin
		rm phpmemcachedadmin.tar.gz
	fi
}

# Opcache Status to provide a dashboard for viewing statistics about PHP's built in opcache.
opcached_status(){
	# Install
	if [[ ! -d "/srv/www/default/opcache-status" ]]; then
		echo -e "\nDownloading Opcache Status, see https://github.com/rlerdorf/opcache-status/"
		cd /srv/www/default
		git clone "https://github.com/rlerdorf/opcache-status.git" opcache-status
	# Update
	else
		echo -e "\nUpdating Opcache Status"
		cd /srv/www/default/opcache-status
		git reset --hard
		git pull --rebase origin master
	fi
}

# Webgrind (for viewing callgrind/cachegrind files produced by xdebug profiler)
webgrind_install() {
	# Install
	if [[ ! -d "/srv/www/default/webgrind" ]]; then
		echo -e "\nDownloading webgrind"
		git clone "https://github.com/michaelschiller/webgrind.git" "/srv/www/default/webgrind"
	# Update
	else
		echo -e "\nUpdating webgrind"
		cd /srv/www/default/webgrind
		git reset --hard
		git pull --rebase origin master
	fi
}

# PHP_CodeSniffer (for running WordPress-Coding-Standards)
php_codesniff() {

	if [[ ! -d "/srv/www/phpcs" ]]; then
		echo -e "\nDownloading PHP_CodeSniffer (phpcs), see https://github.com/squizlabs/PHP_CodeSniffer"
		git clone -b master "https://github.com/squizlabs/PHP_CodeSniffer.git" "/srv/www/phpcs"
	else
		cd /srv/www/phpcs
		if [[ $(git rev-parse --abbrev-ref HEAD) == 'master' ]]; then
			echo -e "\nUpdating PHP_CodeSniffer (phpcs)..."
			git reset --hard
			git pull --no-edit origin master
		else
			echo -e "\nSkipped updating PHP_CodeSniffer since not on master branch"
		fi
	fi

	# Sniffs WordPress Coding Standards
	if [[ ! -d "/srv/www/phpcs/CodeSniffer/Standards/WordPress" ]]; then
		echo -e "\nDownloading WordPress-Coding-Standards for PHP_CodeSniffer"
		git clone -b master "https://github.com/WordPress-Coding-Standards/WordPress-Coding-Standards.git" "/srv/www/phpcs/CodeSniffer/Standards/WordPress"
	else
		cd /srv/www/phpcs/CodeSniffer/Standards/WordPress
		if [[ $(git rev-parse --abbrev-ref HEAD) == 'master' ]]; then
			echo -e "\nUpdating WordPress-Coding-Standards for PHP_CodeSniffer"
			git reset --hard
			git pull --no-edit origin master
		else
			echo -e "\nSkipped updating PHPCS WordPress Coding Standards since not on master branch"
		fi
	fi

	# Install the standards in PHPCS
	/srv/www/phpcs/scripts/phpcs --config-set installed_paths ./CodeSniffer/Standards/WordPress/
	/srv/www/phpcs/scripts/phpcs --config-set default_standard WordPress-Core
	/srv/www/phpcs/scripts/phpcs -i

}

# phpMyAdmin
phpmyadmin_setup() {
  if [[ ! -d /srv/www/default/database-admin ]]; then
    echo "Downloading phpMyAdmin..."
    cd /srv/www/default
    wget -q -O phpmyadmin.tar.gz "https://files.phpmyadmin.net/phpMyAdmin/4.6.0/phpMyAdmin-4.6.0-all-languages.tar.gz"
    tar -xf phpmyadmin.tar.gz
    mv phpMyAdmin-4.6.0-all-languages database-admin
    rm phpmyadmin.tar.gz
  fi
  cp "/srv/config/phpmyadmin-config/config.inc.php" "/srv/www/default/database-admin/"
}

custom_vvv() {

  # Find new sites to setup.
  # Kill previously symlinked Nginx configs.
  # We can't know what sites have been removed, so we have to remove all the configs and add them back in again.
  find /etc/nginx/custom-sites -name 'vvv-auto-*.conf' -exec rm {} \;

  # Look for site setup scripts
  find /srv/www -maxdepth 5 -name 'vvv-init.sh' -print0 | while read -d $'\0' SITE_CONFIG_FILE; do
    DIR="$(dirname "$SITE_CONFIG_FILE")"
    (
    cd "$DIR"
    source vvv-init.sh
    )
  done

  # Look for Nginx vhost files, symlink them into the custom sites dir
  for SITE_CONFIG_FILE in $(find /srv/www -maxdepth 5 -name 'vvv-nginx.conf'); do
    DEST_CONFIG_FILE=${SITE_CONFIG_FILE//\/srv\/www\//}
    DEST_CONFIG_FILE=${DEST_CONFIG_FILE//\//\-}
    DEST_CONFIG_FILE=${DEST_CONFIG_FILE/%-vvv-nginx.conf/}
    DEST_CONFIG_FILE="vvv-auto-$DEST_CONFIG_FILE-$(md5sum <<< "$SITE_CONFIG_FILE" | cut -c1-32).conf"
    # We allow the replacement of the {vvv_path_to_folder} token with whatever you want, allowing flexible placement of the site folder while still having an Nginx config which works.
    DIR="$(dirname "$SITE_CONFIG_FILE")"
    sed "s#{vvv_path_to_folder}#$DIR#" "$SITE_CONFIG_FILE" > "/etc/nginx/custom-sites/""$DEST_CONFIG_FILE"

    # Resolve relative paths since not supported in Nginx root.
    while grep -sqE '/[^/][^/]*/\.\.' "/etc/nginx/custom-sites/""$DEST_CONFIG_FILE"; do
      sed -i 's#/[^/][^/]*/\.\.##g' "/etc/nginx/custom-sites/""$DEST_CONFIG_FILE"
    done
  done

  # Parse any vvv-hosts file located in www/ or subdirectories of www/ for domains to be added to the virtual machine's host file so that it is self aware.
  # Domains should be entered on new lines.
  # Cleaning the virtual machine's /etc/hosts file...
#  sed -n '/# vvv-auto$/!p' /etc/hosts > /tmp/hosts
#  mv /tmp/hosts /etc/hosts
#  echo "Adding domains to the virtual machine's /etc/hosts file..."
#  find /srv/www/ -maxdepth 5 -name 'vvv-hosts' | \
#  while read hostfile; do
#    while IFS='' read -r line || [ -n "$line" ]; do
#      if [[ "#" != ${line:0:1} ]]; then
#        if [[ -z "$(grep -q "^127.0.0.1 $line$" /etc/hosts)" ]]; then
#          echo "127.0.0.1 $line # vvv-auto" >> "/etc/hosts"
#          echo " * Added $line from $hostfile"
#        fi
#      fi
#    done < "$hostfile"
#  done

}

### SCRIPT
#set -xv

network_check
# Profile_setup
echo "Bash profile setup and directories."
profile_setup

network_check
# Package and Tools Install
echo " "
echo "Main packages check and install."
package_install
tools_install
nginx_setup
mailcatcher_setup
phpfpm_setup
services_restart
mysql_setup

network_check
# WP-CLI and debugging tools
echo " "
echo "Installing/updating wp-cli and debugging tools"

wp_cli
memcached_admin
opcached_status
webgrind_install
php_codesniff
phpmyadmin_setup

# VVV custom site import
echo " "
echo "VVV custom site import"
custom_vvv

#set +xv
# And it's done
end_seconds="$(date +%s)"
echo "-----------------------------"
echo "Provisioning complete in "$((${end_seconds} - ${start_seconds}))" seconds"
echo "For further setup instructions, visit http://vvv.dev"
