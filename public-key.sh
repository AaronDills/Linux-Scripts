#!/bin/sh

# @author adills
# This script retrieve's a user's public key from Active Directory and sends the result to standard output. It is meant to be run by the ssh daemon which by default
# passes the username of who is opening the session as the first arguement. dig is used to select a domain controller from a list of available domain controllers.
# The user account connecting to the server is a service account that has credential information stored in a file under /etc/.
# ldapsearch  queries for the user by sam account name and the attribute the public key is stored in. After the attribute is retrieved string
# manipulation is done to grab the public key value. This value is then sent to output.

#If the user is opening a connection as root, send root authorized_keys to stdout
if [[ $! == "root" ]];then
    cat /root/.ssh/authorized_keys
    exit 0
fi

REALM="REALM"
dc_values="dc=realm,dc=com"
attribute="publicKeyAttribute"
server=$(dig +noall +noauthority +answer SRV "_gc._tcp.${REALM}" | sed -re "s|.* ([^ ]*[^. ]).*|\1|"| head -n 1)
username=$(sed -n '1p' /etc/.creds.fs.homes | cut -d '=' -f2)
password=$(sed -n '2p' /etc/.creds.fs.homes | cut -d '=' -f2)
ldapsearch -ZZ -o ldif-wrap=no -x -h $server -D "$username@$REALM" -w $password -b $dc_values "sAMAccountName=$1" $attribute -LLL | grep $attribute | sed "s/$attribute: //g" | sed "s/ecdsa-sha2-nistp521:/ecdsa-sha2-nistp521 /g" | sed "s/ssh-rsa:/ssh-rsa  /g"
