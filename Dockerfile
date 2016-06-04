# Re-use the phusion baseimage adapted for 16.04 which runs an SSH server etc
FROM sunfoxcz/baseimage

# Some definitions
ENV SUDOFILE /etc/sudoers
ENV DEBIAN_FRONTEND noninteractive

COPY change_user_uid.sh /
COPY inventory_file  /etc/ansible/hosts

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        librecode0 \
        libsqlite3-0 \
        libxml2 \
        libffi-dev \
        libpython-dev \
        libssl-dev \
    && \
    rm -r /var/lib/apt/lists/*

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
    touch ${SUDOFILE} && \
    chmod u+w ${SUDOFILE} && \
    echo '%sudo   ALL=(ALL:ALL) NOPASSWD: ALL' >> ${SUDOFILE} && \
    chmod u-w ${SUDOFILE} 
# persistent / runtime deps
RUN apt-get update && apt-get install -y ca-certificates curl librecode0 libsqlite3-0 libxml2 --no-install-recommends && rm -r /var/lib/apt/lists/*


RUN apt-get update && \
    apt-get install -y php7.0-cli php7.0-pgsql php7.0-curl && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

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

ENTRYPOINT /change_user_uid.sh
CMD ["/sbin/my_init"]
