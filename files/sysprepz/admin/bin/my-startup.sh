#!/bin/sh
# restore current users
if [[ -f /vesta/etc-bak/passwd ]]; then
	# restore users
	rsync -a /vesta/etc-bak/passwd /etc/passwd
	rsync -a /vesta/etc-bak/shadow /etc/shadow
	rsync -a /vesta/etc-bak/gshadow /etc/gshadow
	rsync -a /vesta/etc-bak/group /etc/group
fi

# required startup and of course vesta
cd /etc/init.d/
./disable-transparent-hugepages defaults \
&& ./nginx start \
&& ./php7.0-fpm start \
&& ./vesta start
