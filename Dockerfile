# Re-use the phusion baseimage which runs an SSH server etc
FROM phusion/baseimage:0.11

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
    apt-get dist-upgrade -y && \
    apt-get -y install \
        sudo \
        libffi-dev \
        libyaml-dev \
        libssl-dev \
        libpython-dev \
        python \
        python-setuptools   \
        python-pip \
        aptitude \
    && \
    # Enable password-less sudo for all user (including the 'vagrant' user) \
    chmod u+w ${SUDOFILE} && \
    echo '%sudo   ALL=(ALL:ALL) NOPASSWD: ALL' >> ${SUDOFILE} && \
    chmod u-w ${SUDOFILE}

RUN LC_ALL=C.UTF-8 add-apt-repository ppa:ondrej/php -y && \
    apt-get update && \
    apt-get install -y \
        unzip \
        php8.0-cli \
        php8.0-dev \
        php8.0-common \
        php-pear \
        php8.0-zip \
        php8.0-xml \
        php8.0-pgsql \
        php8.0-curl \
        php8.0-imagick \
        php8.0-intl \
        php8.0-sqlite3 \
        # required for magento 2.2
        php8.0-bcmath \
        php8.0-soap \
        php8.0-mysql \
        php8.0-gd \
        php8.0-xsl \
        php8.0-sysvsem \
        php8.0-mbstring \
    && \
    apt-get clean && \
    # install ansible
    pip install --upgrade ansible setuptools && \
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
