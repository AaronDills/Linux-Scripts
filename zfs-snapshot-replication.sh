#!/bin/sh

# @author adills - script to take snapshot of zfs file system and remove snapshots. Default settings for daily snapshot with 2 week of snapshots with 2 week retention.
#snapshots are then sent to another zfs server for backup.

DEST=
RECEIVE_LOC=tank/$hostname
SMB_FILESYSTEM=tank/share
RETENTION=14
NEW_SNAPSHOT="$SMB_FILESYSTEM@"$(date "+%Y-%m-%dT%H:%M:%S")
LAST_RECEIVED_SNAPSHOT=$(ssh -i ~/.ssh/id_rsa root@$DEST "zfs list -t snapshot -o name | grep $RECEIVE_LOC  | tail -1 |  cut -f2 -d'@'")

zfs snapshot $NEW_SNAPSHOT

REMOVE=$(zfs list -t snapshot -o name | grep ^tank/share | tac | tail -n +${RETENTION})
while IFS= read -r snapshot;
do
   if [[ $snapshot ]];then
        zfs destroy -r "$snapshot"
   fi
#done <<< "$REMOVE"

zfs send -vi $LAST_RECEIVED_SNAPSHOT $NEW_SNAPSHOT | ssh -i ~/.ssh/id_rsa root@$DEST zfs receive -Fdv $RECEIVE_LOC
