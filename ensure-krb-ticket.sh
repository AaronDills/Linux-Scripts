#!/bin/sh

#@author - adills
# The purpose of this script is to ensure the machine has a valid KTGT.
# In order we:
# 1. Check ccache for valid ticket
# 2. Attempt to renew ticket in ccache
# 3. Attempt to obtain and cache a new ticket 
# If all these fail we are unable to ensure there is a valid KTGT and the process fails. 

if ! klist -s
then
    if ! net ads kerberos renew -P
    then
       if ! net ads kerberos kinit -P
       then
       		echo "Failed to update or retrieve new KTGT. GSS-API auth will fail."
       		exit 1 
       fi
    fi
fi

echo "Kerberos ticket available for use."
exit 0
