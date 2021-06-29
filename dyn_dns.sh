#!/bin/sh

#@author - adills
# The purpose of this script is to update the forward and reverse dns records of a domain joined machine. The main interface addresses are used, main interface is determined by route.
# Update commands are written to a file which is supplied to nsupdate. GSI auth is used for secure updates.

inf=$(route | grep '^default' | grep -o '[^ ]*$')
ipv4=$(ip -4 addr show $inf | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
ipv6=$(ip -6 addr show $inf  | grep -oP '(?<=inet6\s)[\da-f:]+')
del_fw_ipv4="update delete $(hostname -f). in A"
del_fw_ipv6="update delete $(hostname -f). in AAAA"
cmd_file="/var/run/batch.txt"

function prepare_forward_statements {
        echo $del_fw_ipv4
        while read -r addr;
        do
                echo "update add $(hostname -f) 10 in A $addr"
                echo "send"
        done <<< "$ipv4"
                echo $del_fw_ipv6
        while read -r addr; do
                echo "update add $(hostname -f) 10 in AAAA $addr"
                echo "send"
        done <<< "$ipv6"
}

function rarpa_v6() {
  local idx s=${1//:}
  for (( idx=${#s} - 1; idx>=0; idx-- )); do
    printf '%s.' "${s:$idx:1}"
  done
  printf 'ip6.arpa.'
}

function prepare_reverse_statements {
        while read -r addr; do
                addr=$(echo $addr | awk -F. '{print $4"."$3"." $2"."$1}')
                echo "update delete $addr.in-addr.arpa. in PTR"
                echo "update add $addr.in-addr.arpa. 10 in PTR $(hostname -f)."
                echo "send"
        done <<< "$ipv4"
        while read -r addr; do
                if [[ $addr =~ ^fe80* ]];then continue; fi
                addr=$(rarpa_v6 $(sipcalc $addr | fgrep Expanded | cut -d '-' -f 2))
                echo "update delete $addr in PTR"
                echo "update add $addr 10 in PTR $(hostname -f)."
                echo "send"
        done <<< "$ipv6"

}
prepare_forward_statements > $cmd_file
prepare_reverse_statements >> $cmd_file
nsupdate -g $cmd_file
rm $cmd_file

