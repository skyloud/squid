#!/bin/sh

if [ ! "$1" = "-f" ]; then
    # su-exec "proxy" "$@"
    exec "$@"
    exit 0
fi

set -xe

mkdir -p /etc/squid

truncate -s 0 /etc/squid/squid.conf

echo "cache_log stdio:/var/log/squid/cache.log" >> /etc/squid/squid.conf
echo "access_log stdio:/var/log/squid/access.log" >> /etc/squid/squid.conf
echo "cache_store_log stdio:/var/log/squid/cache_store.log" >> /etc/squid/squid.conf
echo "cache_effective_user proxy" >> /etc/squid/squid.conf

echo "visible_hostname $(hostname)" >> /etc/squid/squid.conf
echo "cache_dir ufs /var/spool/squid 100 16 256" >> /etc/squid/squid.conf

if [[ "${AUTH_USERNAME}" && "${AUTH_PASSWORD}" ]]; then
    htpasswd -cbm /etc/squid/users.htpasswd $AUTH_USERNAME $AUTH_PASSWORD
    echo "auth_param basic program /usr/libexec/squid/basic_ncsa_auth /etc/squid/users.htpasswd" >> /etc/squid/squid.conf
    echo "auth_param basic children 10" >> /etc/squid/squid.conf
    echo "auth_param basic realm ${AUTH_REALM:-"Authentication required"}" >> /etc/squid/squid.conf
    echo "auth_param basic credentialsttl 3 hours" >> /etc/squid/squid.conf
    
    echo "acl users proxy_auth REQUIRED" >> /etc/squid/squid.conf
fi

touch /etc/squid/allowed_domains.txt

if [ ! -z "${ALLOWED_DOMAINS}" ]; then
    echo $ALLOWED_DOMAINS | tr " " "\n" > /etc/squid/allowed_domains.txt
fi

echo "acl all src all" >> /etc/squid/squid.conf
echo "acl safe_ports port 443" >> /etc/squid/squid.conf
echo "acl allow_domains url_regex -i \"/etc/squid/allowed_domains.txt\"" >> /etc/squid/squid.conf

printf "http_access allow" >> /etc/squid/squid.conf

if [[ "${AUTH_USERNAME}" && "${AUTH_PASSWORD}" ]]; then
    printf " users" >> /etc/squid/squid.conf
fi

printf " allow_domains safe_ports\n" >> /etc/squid/squid.conf

echo "http_access deny all" >> /etc/squid/squid.conf

chown -R proxy:proxy /var/run/
chown -R proxy:proxy /var/log/squid/
chown -R proxy:proxy /var/spool/squid/

if [ "${BUMP_SSL_ENABLED}" = "true" ]; then
    mkdir -p /var/lib/squid
    /usr/libexec/squid/security_file_certgen -c -s /var/lib/squid/ssl_db -M 64MB || true

    echo "http_port 3128 tcpkeepalive=60,30,3 ssl-bump generate-host-certificates=on dynamic_cert_mem_cache_size=64MB tls-cert=/etc/squid/bump.crt tls-key=/etc/squid/bump.key cipher=HIGH:MEDIUM:!LOW:!RC4:!SEED:!IDEA:!3DES:!MD5:!EXP:!PSK:!DSS options=NO_TLSv1,NO_SSLv3,SINGLE_DH_USE,SINGLE_ECDH_USE tls-dh=prime256v1:/etc/squid/bump_dhparam.pem" >> /etc/squid/squid.conf

    echo "acl step1 at_step SslBump1" >> /etc/squid/squid.conf
    echo "sslcrtd_program /usr/libexec/squid/security_file_certgen -s /var/lib/squid/ssl_db -M 64MB" >> /etc/squid/squid.conf
    echo "sslproxy_cert_error allow all" >> /etc/squid/squid.conf
    echo "ssl_bump peek step1 all" >> /etc/squid/squid.conf
    echo "ssl_bump bump all" >> /etc/squid/squid.conf
else
    echo "http_port 3128" >> /etc/squid/squid.conf
fi

su-exec "proxy" "squid" "-f" "/etc/squid/squid.conf" "-zN"
su-exec "proxy" "squid" "$@"
