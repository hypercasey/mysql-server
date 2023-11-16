FROM container-registry.oracle.com/os/oraclelinux:9-slim
WORKDIR /container-entrypoint-initdb.d
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
ENV MYSQL_UNIX_PORT=/var/lib/mysql/mysql.sock
ENV mysql_dirs="/var/lib/mysql /var/lib/mysql-files /var/lib/mysql-keyring /var/run/mysqld"

COPY entrypoint.sh /container-entrypoint-initdb.d/entrypoint.sh
COPY healthcheck.sh /container-entrypoint-initdb.d/healthcheck.sh
COPY passworder /container-entrypoint-initdb.d/passworder
RUN chmod 0755 /container-entrypoint-initdb.d/*.sh \
    /container-entrypoint-initdb.d/passworder

# Prepare and install MySQL
RUN microdnf install tar gzip less which sudo net-tools \
    procps-ng openssl openssh-server bash-completion >/dev/null

RUN [[ $(ls /etc/ssh/ssh_host_* | grep 'No such file or directory' >/dev/null) ]] \
    || rm -rf /etc/ssh/ssh_host_* >/dev/null
RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N '' -q >/dev/null
RUN ssh-keygen -t dsa -f /etc/ssh/ssh_host_dsa_key -N '' -q >/dev/null
RUN ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N '' -q >/dev/null
RUN ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N '' -q >/dev/null

RUN [[ ! -f "/etc/passwd" || -z $(grep 3306 /etc/password) ]] \
    && useradd -u 3306 -d /var/lib/mysql -r mysql -M
RUN for dir in $mysql_dirs; do mkdir -p $dir; \
    chmod g+rwx $dir; chgrp -R 0 $dir; done

RUN /container-entrypoint-initdb.d/passworder 16 >/container-entrypoint-initdb.d/.my-password

ARG MYSQL_ROOT_PASSWORD=/container-entrypoint-initdb.d/.my-password
ARG MYSQL_ROOT_HOST=%
ARG MYSQL_USER=hyperuser
ARG MYSQL_PASSWORD=${MYSQL_ROOT_PASSWORD}
ARG MYSQL_DATABASE=hyperserv
ENV MYSQL_ROOT_HOST=$MYSQL_ROOT_HOST
ENV MYSQL_ROOT_PASSWORD=$MYSQL_ROOT_PASSWORD
ENV MYSQL_USER=hyperuser
ENV MYSQL_PASSWORD=${MYSQL_ROOT_PASSWORD}
ENV MYSQL_DATABASE=hyperserv

RUN echo >&2 "[ *** MYSQL_ROOT_PASSWORD: $MYSQL_ROOT_PASSWORD *** ]"

RUN microdnf install mysql-server >/dev/null

RUN microdnf remove policycoreutils python3-policycoreutils \
    policycoreutils-python-utils python3-libselinux \
    python3-libsemanage python3-setools python3-audit >/dev/null

# Create non-root user
RUN [[ ! -f "/etc/passwd" || -z $(grep 1111 /etc/password) ]] \
    && useradd -u 1111 hyperuser -M \
    && mkdir -p /home/hyperuser/.ssh
RUN echo "hyperuser    ALL=(ALL)    NOPASSWD: ALL" >/etc/sudoers.d/11-hyperuser \
    && chmod 0440 /etc/sudoers.d/11-hyperuser
RUN echo '[[ -f "/etc/profile.d/bash_completion.sh" ]] && source "/etc/profile.d/bash_completion.sh"' >/etc/bashrc
RUN rm -f /etc/bashrc
RUN chown -R hyperuser. /home/hyperuser/. \
    && chmod 0700 /home/hyperuser/.ssh
COPY authorized_keys /home/hyperuser/.ssh/authorized_keys
RUN chown hyperuser. /home/hyperuser/.ssh/authorized_keys \
    && chmod 0600 /home/hyperuser/.ssh/authorized_keys
RUN echo "alias ls='sudo ls --color -la'" >>/etc/bashrc
RUN echo "alias grep='sudo grep --color'" >>/etc/bashrc
RUN echo "alias cat='sudo cat'" >>/etc/bashrc
RUN echo "alias chmod='sudo chmod'" >>/etc/bashrc
RUN echo "alias chown='sudo chown'" >>/etc/bashrc
RUN echo "alias dnf='sudo microdnf'" >>/etc/bashrc

LABEL Name="MySQL Server" Version="8.0.26"
LABEL description="MySQL Server - Community Edition"
LABEL org.opencontainers.image.authors="HyperSpire LLC"
LABEL org.opencontainers.image.authors="Casey Comendant casey@hyperspire.com"
LABEL org.opencontainers.image.created="2022-04-16T06:50:00Z"
LABEL org.opencontainers.image.title="MySQL Server"
LABEL org.opencontainers.image.url="phx.ocir.io/axmvl4uui9gb/oracle/mysql-server:latest"
LABEL org.opencontainers.image.vendor="Oracle Corporation"

HEALTHCHECK --interval=30s --timeout=30s --start-period=15s \
    --retries=3 CMD [ "/container-entrypoint-initdb.d/healthcheck.sh" ]
EXPOSE 22/tcp 3306/tcp 33060/tcp 33061/tcp
ENTRYPOINT [ "/container-entrypoint-initdb.d/entrypoint.sh" ]
CMD [ "mysqld" ]
