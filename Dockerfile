FROM alpine:3.12 as build

WORKDIR /build

ADD http://www.squid-cache.org/Versions/v5/squid-5.4.1.tar.gz squid-5.4.1.tar.gz

RUN apk add --no-cache su-exec apache2-utils build-base perl openssl-dev libressl-dev \
    && tar xzf squid-5.4.1.tar.gz \
    && cd squid-5.4.1 \
    && ./configure \
        --prefix=/ \
        --with-default-user=proxy \
        --with-openssl \
        --enable-ssl-crtd \
        --with-gcc-major-version-only \
        --enable-shared \
        --enable-linker-build-id \
        --libexecdir=/usr/libexec/squid \
        --without-included-gettext \
        --enable-threads=posix \
        --libdir=/usr/lib/squid \
        --enable-nls \
        --enable-clocale=gnu \
        --enable-libstdcxx-debug \
        --enable-libstdcxx-time=yes \
        --with-default-libstdcxx-abi=new \
        --enable-gnu-unique-object \
        --disable-vtable-verify \
        --enable-plugin \
        --enable-default-pie \
        --with-system-zlib \
        --with-target-system-zlib=auto \
        --enable-objc-gc=auto \
        --enable-multiarch \
        --disable-werror \
        --with-arch-32=i686 \
        --with-abi=m64 \
        --with-multilib-list=m32,m64,mx32 \
        --enable-multilib \
        --with-tune=generic \
        --enable-offload-targets=nvptx-none=/build/gcc-9-HskZEa/gcc-9-9.3.0/debian/tmp-nvptx/usr,hsa \
        --without-cuda-driver \
        --enable-checking=release \
        --build=x86_64-linux-gnu \
        --host=x86_64-linux-gnu \
        --target=x86_64-linux-gnu \
    && make all \
    && make install \
    && cd /build \
    && rm -fr /build/*

RUN addgroup -S proxy && adduser -S proxy -G proxy

COPY entrypoint.sh /entrypoint.sh

EXPOSE 3128

ENV ALLOWED_DOMAINS ".skyloud.app"
ENV AUTH_USERNAME ""
ENV AUTH_PASSWORD ""

VOLUME ["/var/log/squid", "/var/spool/squid"]

ENTRYPOINT ["/entrypoint.sh"]

CMD ["-f", "/etc/squid/squid.conf", "-NYC"]