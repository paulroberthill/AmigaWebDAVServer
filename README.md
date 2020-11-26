ARexx based WebDAV server.

This is an experimental WebDAV server for the Commodore Amiga.
WebDAV servers can be mounted as a volume on Linux or Windows.

The base mount point will show all devices as folders.

Currently only reading is supported.

# Bugs:
- Empty folders show a "\" entry
- Speed is not great

# Linux:
sudo mount -t davfs -o noexec http://amiga/ /mnt/dav/

# Windows:
net use x: http://amiga

# Amiga configuration:

# RoadShow
Edit devs:internet/servers and add:
www stream dos sys:rexxc/rx [path]/webdavserver.rexx

# Miami


Based on the ARexx Web Server
http://aminet.net/comm/www/arexxwebserver.lha

