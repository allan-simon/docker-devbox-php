# Re-use the phusion baseimage which runs an SSH server etc
FROM phusion/baseimage

# Some definitions
ENV SUDOFILE /etc/sudoers
ENV DEBIAN_FRONTEND noninteractive


COPY change_user_uid.sh /
COPY inventory_file  /etc/ansible/hosts

# Note: we chain all the command in One RUN, so that docker create only one layer
RUN \
    # we permit sshd to be started
    rm -f /etc/service/sshd/down && \
    # we activate empty password with ssh (to simplify login \
    # as it's only a dev machine, it will never be used in production (right?) \
    echo 'PermitEmptyPasswords yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    # we create a user vagrant (so that Vagrant will be happy)
    # without password
    useradd \
        --shell /bin/bash \
        --create-home --base-dir /home \
        --user-group \
        --groups sudo,ssh \
        --password '' \
        vagrant && \
    mkdir -p /home/vagrant/.ssh && \
    chown -R vagrant:vagrant /home/vagrant/.ssh && \
    # Update apt-cache, so that stuff can be installed \
    # Install python (otherwise ansible will not work) \
    # Install aptitude, since ansible needs it (only apt-get is installed) \
    apt-get -y update && \
    apt-get -y install python python-dev python-pip aptitude
RUN \
    apt-get -y install libyaml-dev &&\
    pip install ansible && \
    # Enable password-less sudo for all user (including the 'vagrant' user) \
    chmod u+w ${SUDOFILE} && \
    echo '%sudo   ALL=(ALL:ALL) NOPASSWD: ALL' >> ${SUDOFILE} && \
    chmod u-w ${SUDOFILE} 
# persistent / runtime deps
RUN apt-get update && apt-get install -y ca-certificates curl librecode0 libsqlite3-0 libxml2 --no-install-recommends && rm -r /var/lib/apt/lists/*

# phpize deps
RUN apt-get update && apt-get install -y autoconf file g++ gcc libc-dev make pkg-config re2c --no-install-recommends && rm -r /var/lib/apt/lists/*

ENV PHP_INI_DIR /usr/local/etc/php
RUN mkdir -p $PHP_INI_DIR/conf.d

ENV PHP_VERSION 7.0.0

# --enable-mysqlnd is included below because it's harder to compile after the fact the extensions are (since it's a plugin for several extensions, not an extension in itself)
RUN buildDeps=" \
        $PHP_EXTRA_BUILD_DEPS \
        bison \
        libcurl4-openssl-dev \
        libreadline6-dev \
        librecode-dev \
        libsqlite3-dev \
        libssl-dev \
        libpq-dev \
        libzip-dev \
        libxml2-dev \
        xz-utils \
    " \
    && set -x \
    && apt-get update && apt-get install -y $buildDeps --no-install-recommends && rm -rf /var/lib/apt/lists/* \
    && curl -SL "http://php.net/get/php-$PHP_VERSION.tar.xz/from/this/mirror" -o php.tar.xz \
    && curl -SL "http://php.net/get/php-$PHP_VERSION.tar.xz.asc/from/this/mirror" -o php.tar.xz.asc \
    && gpg --verify php.tar.xz.asc \
    && mkdir -p /usr/src/php \
    && tar -xof php.tar.xz -C /usr/src/php --strip-components=1 \
    && rm php.tar.xz* \
    && cd /usr/src/php \
    && ./configure \
        --with-config-file-path="$PHP_INI_DIR" \
        --with-config-file-scan-dir="$PHP_INI_DIR/conf.d" \
        $PHP_EXTRA_CONFIGURE_ARGS \
        --disable-cgi \
        --enable-mysqlnd \
        --with-curl \
        --with-pgsql \
        --with-openssl \
        --with-readline \
        --with-libzip \
        --with-recode \
        --with-zlib \
    && make -j"$(nproc)" \
    && make install \
    && { find /usr/local/bin /usr/local/sbin -type f -executable -exec strip --strip-all '{}' + || true; } \
    && apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false -o APT::AutoRemove::SuggestsImportant=false $buildDeps \
    && make clean
COPY provisioning/ /provisioning
RUN \
    # run ansible
    ansible-playbook provisioning/site.yml -c local
RUN \
    # clean
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    # we put the 'last time apt-get update was run' file far in the past \
    # so that ansible can then re-run apt-get update \
    touch -t 197001010000 /var/lib/apt/periodic/update-success-stamp
COPY docker-php-ext-* /usr/bin/
RUN \
    chmod +x /usr/bin/docker-php* && \
    apt-get update && apt-get install -y libpq-dev libzip-dev --no-install-recommends && rm -rf /var/lib/apt/lists/* && \
    docker-php-ext-install pdo && \
    docker-php-ext-install pdo_pgsql && \
    docker-php-ext-install zip

ENTRYPOINT /change_user_uid.sh
CMD ["/sbin/my_init"]
