#!/bin/bash
# set -e: exit asap if a command exits with a non-zero status
set -e
trap ctrl_c INT
function ctrl_c() {
  exit 0
}

# entrypoint.sh file for starting the xvfb with better screen resolution, configuring and running the vnc server.

rm /tmp/.X1-lock 2> /dev/null &

/opt/noVNC/utils/novnc_proxy --vnc localhost:$VNC_PORT --listen $NO_VNC_PORT --cert /data/secrets/ssl/self.pem &

# Insecure option is needed to accept connections from the docker host.
vncserver $DISPLAY -depth $VNC_COL_DEPTH -geometry $VNC_RESOLUTION -SecurityTypes None -localhost no --I-KNOW-THIS-IS-INSECURE &

/data/bin/kDrive.AppImage --logdir /data/logs --logexpire 24 &  # since --confdir does not work properly, this directory is symlinked

wait
