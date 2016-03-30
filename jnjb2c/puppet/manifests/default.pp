# mysql root password
$mysqlpw = "3.1415926"

$php_version = '5.6'

# default executable path
Exec {
    path => ["/usr/bin", "/bin", "/usr/sbin", "/sbin", "/usr/local/bin", "/usr/local/sbin"],
}

# update apt sources list
file { "/etc/apt/sources.list":
    source => "puppet:///modules/apt/sources.list",
}

# ensure local apt cache index is up to date at beginning
exec { "apt-get update":
    require => File["/etc/apt/sources.list"],
}

# silence puppet and vagrant annoyance about the puppet group
group { "puppet":
    ensure => "present",
}

include tools, jnjb2c

class tools {
    apt::install{ [ "vim", "curl", "htop" ]: }
}

class mysql {
    apt::install{ ["mysql-server"]: }

    # start mysql service
    service { "mysql":
        ensure => running,
        require => Package["mysql-server"],
    }

    # set mysql root password
    exec { "set-mysql-password":
        unless => "mysqladmin -uroot -p$mysqlpw status",
        command => "mysqladmin -uroot password $mysqlpw",
        require => Service["mysql"],
    }
}

class apache {
    apt::install{ ["apache2"]: }

    # start the apache2 service
    service { "apache2":
        ensure => running,
        require => Package["apache2"],
    }

    apache::module { ['ssl.load', 'rewrite.load']: }

    file { "/etc/apache2/sites-enabled/000-default.conf":
        ensure => absent,
        notify => Service["apache2"],
        require => Package["apache2"],
    }
}

class apache-mod_php {
    include php, apache

    if $php_version == '5.6' {
        file { "/etc/php5/apache2/php.ini":
            source => "puppet:///modules/php56/php.ini",
            backup => '.original',
            notify => Service["apache2"],
            require => Package["php5"],
        }
    }
    else {
        file { "/etc/php5/apache2/php.ini":
            source => "puppet:///modules/php/php.ini",
            backup => '.original',
            notify => Service["apache2"],
            require => Package["php5"],
        }
    }

    # change apache user and group to vagrant to avoid privilegs issues
    exec { "echo 'export APACHE_RUN_USER=vagrant' >> /etc/apache2/envvars; echo 'export APACHE_RUN_GROUP=vagrant' >> /etc/apache2/envvars":
        unless => "grep -q 'APACHE_RUN_USER=vagrant' /etc/apache2/envvars",
        notify => Service["apache2"],
        require => Package["apache2"],
    }
}

class apache-fastcgi {
    include apache, php-fpm

    if $php_version == '5.6' {
        file { "/etc/php5/fpm/php.ini":
            source => "puppet:///modules/php56/php.ini",
            backup => '.original',
            require => Package["php5-fpm"],
        }
    }
    else {
        file { "/etc/php5/fpm/php.ini":
            source => "puppet:///modules/php/php.ini",
            backup => '.original',
            require => Package["php5-fpm"],
        }
    }

    apt::install{ ["libapache2-mod-fastcgi"]: }

    exec { "a2dismod php5":
        require => Package["apache2"],
    }

    apache::module { ['actions.conf', 'actions.load', 'fastcgi.conf', 'fastcgi.load']: }
}

class memcache {
    apt::install{ [ "memcached" ]: }

    # start the memcached service
    service { "memcached":
        ensure => running,
        require => Package["memcached"],
    }
}

class php {
    if $php_version == '5.6' {
        apt::install{ [ "software-properties-common", "python-software-properties" ]: }

        exec { "add-apt-repository ppa:ondrej/php5-5.6":
            require => [
                Package["python-software-properties"],
                Package["software-properties-common"]
            ]
        }

        exec { "Update the APT sources again":
            command => "apt-get update",
            require => [
                File["/etc/apt/sources.list"],
                Exec["add-apt-repository ppa:ondrej/php5-5.6"]
            ]
        }
    }

    apt::install{ [ "php5", "php5-curl", "php5-mysql", "php5-xdebug", "php5-memcached" ]: }

    exec { "php5enmod mcrypt":
        require => Package["php5"],
    }

    file { "/etc/php5/mods-available/xdebug.ini":
        source => "puppet:///modules/php/xdebug.ini",
        backup => '.original',
        require => Package["php5-xdebug"],
    }
}

class php-fpm {
    include php

    apt::install{ [ "php5-fpm" ]: }

    service { "php5-fpm":
        ensure => running,
    }
}

class phpmyadmin {
    apt::install { ["phpmyadmin"]: }

    file { "/etc/apache2/conf-available/phpmyadmin.conf":
        ensure => link,
        target => "/etc/phpmyadmin/apache.conf",
    }

    exec { "import-phpmyadmin-database":
        require => [
            Package["phpmyadmin"],
            Exec["set-mysql-password"]
        ],
        command => "zcat /usr/share/doc/phpmyadmin/examples/create_tables.sql.gz | mysql -uroot -p$mysqlpw",
    }

    exec { "configure-phpmyadmin-controlled-users":
        require => Exec["import-phpmyadmin-database"],
        command => "mysql -uroot -p$mysqlpw -e \"GRANT ALL ON \\`phpmyadmin\\`.* TO 'phpmyadmin'@'localhost' IDENTIFIED BY '$mysqlpw';\"",
    }

    exec { "correct-phpmyadmin-configured-table-names":
        unless => "grep -q 'pma__' /etc/phpmyadmin/config.inc.php",
        require => Package["phpmyadmin"],
        command => "sed -i 's/pma_/pma__/g' /etc/phpmyadmin/config.inc.php",
    }

    file { "/etc/phpmyadmin/config-db.php":
        source => "puppet:///modules/phpmyadmin/config-db.php",
        require => Package["phpmyadmin"],
    }

    apache::conf { ['phpmyadmin.conf']: }
}

class jnjb2c {
    include mysql, memcache, apache-fastcgi, phpmyadmin

    apt::install { ["drush"]: }

    file { "/var/www/jnjb2c":
        ensure => directory,
        require => Package["apache2"],
    }

    file { "/etc/php5/fpm/pool.d/www.conf":
        ensure => absent,
        notify => Service["php5-fpm"],
        require => Package["php5-fpm"],
    }

    file { "/etc/php5/fpm/pool.d/jnjb2c.conf":
        source => "puppet:///modules/php/fpm/pool.d/sample.conf",
        backup => '.original',
        notify => Service["php5-fpm"],
        require => Package["php5-fpm"],
    }

    # create jnjb2c database
    exec { "create-mysql-database":
        unless => "echo 'SHOW DATABASES' | mysql -uroot -p$mysqlpw | grep jnjb2c",
        command => "echo 'CREATE DATABASE jnjb2c' | mysql -uroot -p$mysqlpw",
        require => Exec["set-mysql-password"],
    }

    apache::vhost { ["jnjb2c"]: }
}

define apt::install() {
    package { "${name}":
        ensure => present,
        require => Exec["apt-get update"],
    }
}

define apache::conf() {
    file { "/etc/apache2/conf-enabled/${name}":
        ensure => link,
        target => "../conf-available/${name}",
        notify => Service["apache2"],
        require => [
            File["/etc/apache2/conf-available/${name}"],
            Package["apache2"],
        ]
    }
}

define apache::vhost() {
    file {
        "/etc/apache2/sites-enabled/${name}.conf":
            ensure => link,
            target => "../sites-available/${name}.conf",
            notify => Service["apache2"],
            require => File["/etc/apache2/sites-available/${name}.conf"];

        "/etc/apache2/sites-available/${name}.conf":
            source => "puppet:///modules/apache/vhosts/jnjb2c.conf",
            require => Package["apache2"];

        "/etc/apache2/sites-enabled/${name}-ssl.conf":
            ensure => link,
            target => "../sites-available/${name}-ssl.conf",
            notify => Service["apache2"],
            require => File["/etc/apache2/sites-available/${name}-ssl.conf"];

        "/etc/apache2/sites-available/${name}-ssl.conf":
            source => "puppet:///modules/apache/vhosts/jnjb2c-ssl.conf",
            require => Package["apache2"];
    }
}

define apache::module() {
    file { "/etc/apache2/mods-enabled/${name}":
        ensure => link,
        target => "../mods-available/${name}",
        notify => Service['apache2'],
        require => Package['apache2'],
    }
}
