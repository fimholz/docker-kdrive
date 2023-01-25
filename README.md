# Infomaniak kDrive in docker

**If you are here to find anything which is secure and well-tested: sorry.**

Why *kDrive in docker*? A few thoughts...
1. I'm a customer of Infomaniak's [kDrive](https://www.infomaniak.com/en/kdrive)
1. I want to bisync between my local storage and their WebDAV server
1. I'm using Linux
1. I don't want to install an App on my local drive which could eat up to 2TB when my kDrive space gets full (on Linux you cannot use LiteSync)
1. As far as I know, there does not exist a command line application for Infomaniak's kDrive, which is basically a fork of the Owncloud Client
1. Therefore kDrive depends on a GUI
1. It's getting worse to say that this app also depends on the systray. You can do quite **nothing** without that!
1. The app is distributed as an AppImage (with some dependencies you need to figure out by yourself)

Okay then, let's try it. In my case on Proxmox PVE, installed on a not very powerful (but powerful) HP ThinClient T630 which runs an OpenMediaVault VM which runs docker. You are right, I could run this container outside of OMV on a dedicated docker host, but please note the heading [Synctarget](#synctarget) below.

The goals:
1. access all data locally with and without a working connection to the internet: music, videos, photos, docs, ...
1. use OMV as the only local fileserver, other devices can connect to it using SMB or NFS. No need to install the kDrive app on multiple devices
1. kDrive (or another/better app) is just an interface to the remote WebDAV server and does what it should: synchronize

You have a better way to bisync to a WebDAV server? Let me know and we can discuss about!

## Examples

### build

```docker build -t fimholz/kdrive:latest .```

### run example

```
docker run -d \
  --cap-add SYS_ADMIN \
  --cap-add IPC_LOCK \
  --device /dev/fuse \
  --security-opt apparmor:unconfined \
  -e 'TZ=Europe/Zurich' \
  -p 5901:5901 \
  -p 6901:6901 \
  -v kdrive_data:/data \
  --mount type=bind,source=/source/on/the/host,target=/target/in/the/container \
  --name 'kDrive' \
  --restart unless-stopped \
  fimholz/kdrive:latest
```

#### FUSE

kDrive will not start without being able to use FUSE. The following parameters are for this purpose: ```--cap-add SYS_ADMIN```, ```--device /dev/fuse``` and ```--security-opt apparmor:unconfined```

#### gnome-keyring

Needed to store the credentials of the kDrive connection: ```--cap-add IPC_LOCK```

*The default keyring is stored on the ```/data``` volume. When connecting for the first time you will be asked to enter a password for the new created keyring. You can use a blank password to unlock the keyring automatically, otherwise you would need to enter the credentials on every container restart. I know this is bad practice but I have no idea how to get rid of this.*

#### data Volume

...where the things are stored, which should survive a container restart: logs, configs, credentials, binaries

The kDrive.AppImage is also stored there to be able to update the app without rebuilding the container

#### Synctarget
Use a bind-mount or a local volume. Since kDrive uses SQLite databases, network shares are not recommended because of the locking mechanisms.

#### Ports
* 5901: connect with a VNC viewer
* 6901: connect to noVNC with your browser
