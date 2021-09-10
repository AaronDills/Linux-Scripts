#!/bin/sh

mv /var/lib/samba/private /tmp
rm -rf /var/lib/samba/*
systemctl stop smb
systemctl stop winbind
mv /tmp/private /var/lib/samba
systemctl start smb
systemctl start winbind
