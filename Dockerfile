FROM niiknow/docker-hostingbase:0.8.4

MAINTAINER argami@gmail.com

ENV DEBIAN_FRONTEND=noninteractive
ENV VESTA=/vesta

# start
RUN apt-get update && apt-get -y upgrade && apt-get install -y net-tools

ADD ./vst-install-ubuntu.sh /tmp/

RUN sed -i -e "s/mysql\-/mariadb\-/g" /tmp/vst-install-ubuntu.sh

# begin VestaCP install
RUN bash /tmp/vst-install-ubuntu.sh \
        --nginx yes --apache no --phpfpm yes \
        --vsftpd no --proftpd no \
        --named yes --exim no --dovecot no \
        --spamassassin no --clamav no \
        --iptables no --fail2ban no \
        --mysql yes --postgresql no --remi no \
        --quota yes --password Test123 \
        -y no -f

RUN apt-get -yf autoremove && apt-get clean

ADD ./files /

# tweaks
RUN \
    cd /tmp \
    && chmod +x /etc/service/sshd/run \
    && chmod +x /etc/my_init.d/startup.sh \

 
    && sed -i -e "s/PermitRootLogin prohibit-password/PermitRootLogin no/g" /etc/ssh/sshd_config \

    && cd /vesta/data/ips && mv * 127.0.0.1 \
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
    && sed -i -e "s/\%ip\%\:\%proxy\_port\%\;/\%proxy\_port\%\;/g" /vesta/data/templates/web/nginx/*.tpl \
    && sed -i -e "s/\%ip\%\:\%proxy\_ssl\_port\%\;/\%proxy\_ssl\_port\%\;/g" /vesta/data/templates/web/nginx/*.stpl \
    && sed -i -e "s/\%ip\%\:\%proxy\_port\%\;/\%proxy\_port\%\;/g" /vesta/data/templates/web/nginx/php-fpm/*.tpl \
    && sed -i -e "s/\%ip\%\:\%proxy\_ssl\_port\%\;/\%proxy\_ssl\_port\%\;/g" /vesta/data/templates/web/nginx/php-fpm/*.stpl \
    && sed -i -e "s/^worker_rlimit_nofile    65535;//g" /etc/nginx/nginx.conf \
    && sed -i -e "s/unzip/unzip \-o/g" /vesta/bin/v-extract-fs-archive \
    && sed -i -e "s/^NAT=.*/NAT=\'\'/g" /vesta/data/ips/* 

    && mkdir -p /sysprepz/home \
    && rsync -a /home/* /sysprepz/home \

    && mkdir -p /vesta-start/local/vesta/data/sessions \
    && chmod 775 /vesta-start/local/vesta/data/sessions \
    && chown root:admin /vesta-start/local/vesta/data/sessions \

    && rm -rf /backup/.etc \
    && rm -rf /tmp/*


VOLUME ["/vesta", "/home", "/backup"]

EXPOSE 22 25 53 54 80 110 443 993 1194 3000 3306 5432 5984 6379 8083 10022 11211 27017
