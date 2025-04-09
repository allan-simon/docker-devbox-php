# Re-use the phusion baseimage which runs an SSH server etc
FROM phusion/baseimage:noble-1.0.0

# Some definitions
ENV SUDOFILE /etc/sudoers
ENV DEBIAN_FRONTEND noninteractive

COPY change_user_uid.sh /
COPY inventory_file  /etc/ansible/hosts


# Note: we chain all the command in One RUN, so that docker create only one layer
RUN \
    ln -s /usr/bin/dpkg-split /usr/sbin/dpkg-split && \
    ln -s /usr/bin/dpkg-deb /usr/sbin/dpkg-deb && \
    ln -s /bin/rm /usr/sbin/rm && \
    ln -s /bin/tar /usr/sbin/tar  && \
    # we permit sshd to be started
    rm -f /etc/service/sshd/down && \
    # we activate empty password with ssh (to simplify login \
    # as it's only a dev machine, it will never be used in production (right?) \
    echo 'PermitEmptyPasswords yes' >> /etc/ssh/sshd_config && \
    echo 'PasswordAuthentication yes' >> /etc/ssh/sshd_config && \
    # we remove the ubuntu user
    userdel ubuntu && \
    # we create a user vagrant (so that Vagrant will be happy)
    # without password
    useradd \
        --shell /bin/bash \
        --create-home --base-dir /home \
        --user-group \
        --groups sudo \
        --password '' \
        vagrant && \
    mkdir -p /home/vagrant/.ssh && \
    chown -R vagrant:vagrant /home/vagrant/.ssh && \
    # Update apt-cache, so that stuff can be installed \
    # Install python (otherwise ansible will not work) \
    # Install aptitude, since ansible needs it (only apt-get is installed) \
    apt-get -y update && \
    apt-get -y install sudo wget python3 python3-dev python3-pip aptitude libfaketime libssl-dev autoconf libtool make unzip && \
    apt-get -y upgrade && \
    apt remove -y curl && apt purge curl && \
    # Install cURL version 7.88.1 as it's not compatible with the latest version
    # of OpenSSL. See: https://stackoverflow.com/a/75867650
    cd /tmp && rm -rf curl* && \
    wget https://curl.haxx.se/download/curl-7.88.1.zip && \
    unzip curl-7.88.1.zip && cd curl-7.88.1 && \
    ./buildconf && ./configure --with-ssl && \
    make && make install && \
    cp /usr/local/bin/curl /usr/bin/curl && \
    # Fix the LDD link issue: https://github.com/curl/curl/issues/4448
    # We do this because removing the old cURL version did not remove its libraries
    # and the new cURL version is first loading these one instead of the new ones
    rm -rf /usr/lib/`uname -p`-linux-gnu/libcurl.so* && ldconfig && \
    # Enable password-less sudo for all user (including the 'vagrant' user) \
    chmod u+w ${SUDOFILE} && \
    echo '%sudo   ALL=(ALL:ALL) NOPASSWD: ALL' >> ${SUDOFILE} && \
    chmod u-w ${SUDOFILE}

RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php -y && \
    apt-get update && \
    apt-get install -y \
        unzip \
        ansible \
        php8.4-cli \
        php8.4-dev \
        php8.4-common \
        php8.4-zip \
        php8.4-xml \
        php8.4-pgsql \
        php8.4-curl \
        php8.4-imagick \
        php8.4-imap \
        php8.4-pcov \
        php8.4-intl \
        php8.4-sqlite3 \
        php8.4-bcmath \
        php8.4-soap \
        php8.4-mysql \
        php8.4-gd \
        php8.4-xsl \
        php8.4-sysvsem \
        php8.4-mbstring \
        php8.4-xdebug \
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    # we put the 'last time apt-get update was run' file far in the past \
    # so that ansible can then re-run apt-get update \
    touch -t 197001010000 /var/lib/apt/periodic/update-success-stamp && \
    # fix the tty error on vagrant \
    sed -i '/tty/!s/mesg n/true/' /root/.profile

COPY provisioning/ /provisioning
RUN \
    # run ansible
    ansible-playbook provisioning/site.yml -c local && \
    chown -R vagrant /home/vagrant

RUN \
    # clean
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    # we put the 'last time apt-get update was run' file far in the past \
    # so that ansible can then re-run apt-get update \
    touch -t 197001010000 /var/lib/apt/periodic/update-success-stamp

ENTRYPOINT /change_user_uid.sh
CMD ["/sbin/my_init"]
