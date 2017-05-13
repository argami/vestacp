FROM niiknow/docker-hostingbase:0.8.4

MAINTAINER argami@gmail.com

ENV DEBIAN_FRONTEND=noninteractive
ENV VESTA=/usr/local/vesta

# start
RUN \
    cd /tmp \
    && apt-get update && apt-get -y upgrade

# # setting up dotnet, awscli, golang, php
# RUN \
#     cd /tmp \
#
# # install php
#     && apt-get install -yq php5.6-mbstring php5.6-cgi php5.6-cli php5.6-dev php5.6-geoip php5.6-common php5.6-xmlrpc php5.6-sybase \
#         php5.6-curl php5.6-enchant php5.6-imap php5.6-xsl php5.6-mysql php5.6-mysqlnd php5.6-pspell php5.6-gd php5.6-zip \
#         php5.6-tidy php5.6-opcache php5.6-json php5.6-bz2 php5.6-pgsql php5.6-mcrypt php5.6-readline php5.6-imagick \
#         php5.6-intl php5.6-sqlite3 php5.6-ldap php5.6-xml php5.6-redis php5.6-dev \
#
#     && apt-get install -yq php7.0-mbstring php7.0-cgi php7.0-cli php7.0-dev php7.0-geoip php7.0-common php7.0-xmlrpc php7.0-sybase \
#         php7.0-curl php7.0-enchant php7.0-imap php7.0-xsl php7.0-mysql php7.0-mysqlnd php7.0-pspell php7.0-gd php7.0-zip \
#         php7.0-tidy php7.0-opcache php7.0-json php7.0-bz2 php7.0-pgsql php7.0-mcrypt php7.0-readline php7.0-imagick \
#         php7.0-intl php7.0-sqlite3 php7.0-ldap php7.0-xml php7.0-redis php7.0-dev \
#
#     && apt-get install -yq php7.1-mbstring php7.1-cgi php7.1-cli php7.1-dev php7.1-geoip php7.1-common php7.1-xmlrpc php7.1-sybase \
#         php7.1-curl php7.1-enchant php7.1-imap php7.1-xsl php7.1-mysql php7.1-mysqlnd php7.1-pspell php7.1-gd php7.1-zip \
#         php7.1-tidy php7.1-opcache php7.1-json php7.1-bz2 php7.1-pgsql php7.1-mcrypt php7.1-readline php7.1-imagick \
#         php7.1-intl php7.1-sqlite3 php7.1-ldap php7.1-xml php7.1-redis php7.1-dev


RUN apt-get install -y net-tools

ADD ./vst-install-ubuntu.sh /tmp/

RUN \
    cd /tmp \
    # && curl -s -o /tmp/vst-install-ubuntu.sh https://vestacp.com/pub/vst-install-ubuntu.sh \

# fix mariadb instead of mysql and php7.0 instead of php7.1
    && sed -i -e "s/mysql\-/mariadb\-/g" /tmp/vst-install-ubuntu.sh
    # && sed -i -e "s/\-php php /\-php php7\.0 /g" /tmp/vst-install-ubuntu.sh \
    # && sed -i -e "s/php\-/php7\.0\-/g" /tmp/vst-install-ubuntu.sh \
    # && sed -i -e "s/libapache2\-mod\-php/libapache2-mod\-php7\.0/g" /tmp/vst-install-ubuntu.sh

# begin VestaCP install
RUN bash /tmp/vst-install-ubuntu.sh \
        --nginx yes --apache no --phpfpm yes \
        --vsftpd no --proftpd no \
        --named yes --exim no --dovecot no \
        --spamassassin no --clamav no \
        --iptables no --fail2ban no \
        --mysql yes --postgresql no --remi no \
        --quota yes --password Test123 \
        -y no -f \
        
    # &&  bash /tmp/vst-install-ubuntu.sh \
    #     -y no -f  --nginx yes --phpfpm yes \
    #     --apache no --named yes --remi no \
    #     --vsftpd yes --proftpd no --iptables no \
    #     --fail2ban no --quota no --exim no --dovecot no \
    #     --spamassassin no --clamav no --mysql no \
    #     --postgresql no --hostname blogs.killia.com \
    #     --email it@killia.com --password admin \

# cleanup
    # && service apache2 stop \
    # && apt-get install -yf libapache2-mod-php5.6 libapache2-mod-php7.1 && a2dismod php5.6 && a2dismod php7.0 && a2dismod php7.1 \

# fix v8js reference of json first
    # && mv /etc/php/5.6/apache2/conf.d/20-json.ini /etc/php/5.6/apache2/conf.d/15-json.ini \
# RUN mv /etc/php/5.6/cli/conf.d/20-json.ini /etc/php/5.6/cli/conf.d/15-json.ini \
#     && mv /etc/php/5.6/cgi/conf.d/20-json.ini /etc/php/5.6/cgi/conf.d/15-json.ini \

# switch to php7.0 version as default
    # && update-alternatives --set php /usr/bin/php7.0 \
    # && pecl config-set php_ini /etc/php/7.0/cli/php.ini \
    # && pecl config-set ext_dir /usr/lib/php/20151012 \
    # && pecl config-set bin_dir /usr/bin \
    # && pecl config-set php_bin /usr/bin/php7.0 \
    # && pecl config-set php_suffix 7.0 \
    # && a2enmod php7.0 \

# restore php-cgi to php7.0
    # && mv /usr/bin/php-cgi /usr/bin/php-cgi-old \
    # && ln -s /usr/bin/php-cgi7.0 /usr/bin/php-cgi \

RUN rm -rf /tmp/* \
    && apt-get -yf autoremove \
    && apt-get clean 

ADD ./files /

# tweaks
RUN \
    cd /tmp \
    && chmod +x /etc/service/sshd/run \
    && chmod +x /etc/my_init.d/startup.sh \

 
    && sed -i -e "s/PermitRootLogin prohibit-password/PermitRootLogin no/g" /etc/ssh/sshd_config \

    && cd /usr/local/vesta/data/ips && mv * 127.0.0.1 \
    && cd /etc/nginx/conf.d \
    && sed -i -- 's/172.*.*.*:80;/80;/g' * && sed -i -- 's/172.*.*.*:8080/127.0.0.1:8080/g' * \
    && sed -i -e "s/^#PermitRootLogin yes/PermitRootLogin no/g" /etc/ssh/sshd_config \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.1/cli/php.ini \
    && sed -i "s/upload_max_filesize = 2M/upload_max_filesize = 600M/" /etc/php/7.1/cgi/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.1/cli/php.ini \
    && sed -i "s/post_max_size = 8M/post_max_size = 600M/" /etc/php/7.1/cgi/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.1/cli/php.ini \
    && sed -i "s/max_input_time = 60/max_input_time = 3600/" /etc/php/7.1/cgi/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 3600/" /etc/php/7.1/cli/php.ini \
    && sed -i "s/max_execution_time = 30/max_execution_time = 3600/" /etc/php/7.1/cgi/php.ini \
    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.1/cli/php.ini \
    && sed -i -e "s/;sendmail_path =/sendmail_path = \/usr\/sbin\/exim \-t/g" /etc/php/7.1/cgi/php.ini \
    && sed -i -e "s/\%ip\%\:\%proxy\_port\%\;/\%proxy\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/*.tpl \
    && sed -i -e "s/\%ip\%\:\%proxy\_ssl\_port\%\;/\%proxy\_ssl\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/*.stpl \
    && sed -i -e "s/\%ip\%\:\%proxy\_port\%\;/\%proxy\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/php-fpm/*.tpl \
    && sed -i -e "s/\%ip\%\:\%proxy\_ssl\_port\%\;/\%proxy\_ssl\_port\%\;/g" /usr/local/vesta/data/templates/web/nginx/php-fpm/*.stpl \
    && bash /usr/local/vesta/upd/switch_rpath.sh \
    && sed -i -e "s/^worker_rlimit_nofile    65535;//g" /etc/nginx/nginx.conf \
    && sed -i -e "s/unzip/unzip \-o/g" /usr/local/vesta/bin/v-extract-fs-archive \
    && sed -i -e "s/^NAT=.*/NAT=\'\'/g" /usr/local/vesta/data/ips/* \

    # && mkdir -p /vesta-start/etc \
    # && mkdir -p /vesta-start/var/lib \
    # && mkdir -p /vesta-start/local \
    #
    # && mv /etc/ssh /vesta-start/etc/ssh \
    # && rm -rf /etc/ssh \
    # && ln -s /vesta/etc/ssh /etc/ssh \
    #
    # && mv /etc/php /vesta-start/etc/php \
    # && rm -rf /etc/php \
    # && ln -s /vesta/etc/php /etc/php \
    #
    # && mv /etc/nginx   /vesta-start/etc/nginx \
    # && rm -rf /etc/nginx \
    # && ln -s /vesta/etc/nginx /etc/nginx \
    #
    # && mv /root /vesta-start/root \
    # && rm -rf /root \
    # && ln -s /vesta/root /root \
    #
    # && mv /usr/local/vesta /vesta-start/local/vesta \
    # && rm -rf /usr/local/vesta \
    # && ln -s /vesta/local/vesta /usr/local/vesta \
    #
    # && mv /etc/timezone /vesta-start/etc/timezone \
    # && rm -rf /etc/timezone \
    # && ln -s /vesta/etc/timezone /etc/timezone \
    #
    # && mv /etc/bind /vesta-start/etc/bind \
    # && rm -rf /etc/bind \
    # && ln -s /vesta/etc/bind /etc/bind \
    #
    # && mv /etc/profile /vesta-start/etc/profile \
    # && rm -rf /etc/profile \
    # && ln -s /vesta/etc/profile /etc/profile \
    #
    # && mv /var/log /vesta-start/var/log \
    # && rm -rf /var/log \
    # && ln -s /vesta/var/log /var/log \
    #
    # && mkdir /vesta-start/data \
    # && ln -s /vesta/data /data \

    && mkdir -p /sysprepz/home \
    && rsync -a /home/* /sysprepz/home \

    && mkdir -p /vesta-start/local/vesta/data/sessions \
    && chmod 775 /vesta-start/local/vesta/data/sessions \
    && chown root:admin /vesta-start/local/vesta/data/sessions \

    && rm -rf /backup/.etc \
    && rm -rf /tmp/*


VOLUME ["/usr/local/vesta", "/home", "/backup"]

EXPOSE 22 25 53 54 80 110 443 993 1194 3000 3306 5432 5984 6379 8083 10022 11211 27017
