FROM debian:11-slim

ENV DISPLAY=:1 \
    VNC_PORT=5901 \
    NO_VNC_PORT=6901 \
    VNC_COL_DEPTH=16 \
    VNC_RESOLUTION=1280x960

# No interactive frontend during docker build
ENV DEBIAN_FRONTEND=noninteractive

# Install packages
RUN apt-get update && \
    apt-get install --no-install-recommends -y \
    xvfb xauth dbus-x11 xfce4 xfce4-terminal \
    wget sudo curl gpg git bzip2 vim procps python x11-xserver-utils \
    libnss3 libnspr4 libasound2 libgbm1 ca-certificates fonts-liberation xdg-utils \
    tigervnc-standalone-server tigervnc-common \
    gnome-keyring libsecret-tools \
    fuse libegl1 libopengl0; \
    curl http://ftp.us.debian.org/debian/pool/main/liba/libappindicator/libappindicator3-1_0.4.92-7_amd64.deb --output /opt/libappindicator3-1_0.4.92-7_amd64.deb && \
    curl http://ftp.us.debian.org/debian/pool/main/libi/libindicator/libindicator3-7_0.5.0-4_amd64.deb --output /opt/libindicator3-7_0.5.0-4_amd64.deb && \
    apt-get install -y /opt/libappindicator3-1_0.4.92-7_amd64.deb /opt/libindicator3-7_0.5.0-4_amd64.deb; \
    rm -vf /opt/lib*.deb; \
    apt-get clean; \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ENV TERM xterm

# Install NOVNC.
RUN git -c advice.detachedHead=false clone --branch v1.4.0 --single-branch https://github.com/novnc/noVNC.git /opt/noVNC; \
    git -c advice.detachedHead=false clone --branch v0.11.0 --single-branch https://github.com/novnc/websockify.git /opt/noVNC/utils/websockify; \
    ln -s /opt/noVNC/vnc.html /opt/noVNC/index.html

# disable shared memory X11 affecting Chromium
ENV QT_X11_NO_MITSHM=1 \
    _X11_NO_MITSHM=1 \
    _MITSHM=0

# Create user and copy xfce4 settings
RUN groupadd -g 1000 dockeruser; \
    useradd -g 1000 -G users -l -m -s /bin/bash -u 1000 dockeruser; \
    adduser dockeruser sudo; \
    echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
COPY --chown=dockeruser:dockeruser assets/config/ /home/dockeruser/.config

# Create retention data dirs and ssl keys
WORKDIR /data
RUN mkdir -p bin config logs secrets/keyrings secrets/ssl; \
    openssl req -new -x509 -days 365 -nodes \
                -subj "/C=CA/ST=QC/O=Company, Inc./CN=mydomain.com" -addext "subjectAltName=DNS:mydomain.com" \
                -out /data/secrets/ssl/self.pem -keyout /data/secrets/ssl/self.pem; \
    chown -R dockeruser:dockeruser /data
COPY --chown=dockeruser:dockeruser scripts/entrypoint.sh /data/bin/entrypoint.sh

# Install app
USER dockeruser
RUN wget --no-verbose https://download.storage.infomaniak.com/drive/desktopclient/kDrive-3.3.7.20221109.AppImage -O /data/bin/kDrive.AppImage; \
    chmod +x /data/bin/kDrive.AppImage; \
    mkdir -p /home/dockeruser/.local/share; mkdir -p /home/dockeruser/.config; \
    ln -s /data/secrets/keyrings /home/dockeruser/.local/share/keyrings; \
    ln -s /data/config /home/dockeruser/.config/kDrive


# VNC:   5901
# noVNC: 6901
EXPOSE 5901 6901
ENTRYPOINT ["/data/bin/entrypoint.sh"]
