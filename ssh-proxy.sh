#!/bin/bash

#
# ssh-proxy.sh
#
#
# Usage:
#   ssh-proxy someproxy.somedomain.com somehost.somedomain.com [optional_port]
#

if [ -z "$1" ]; then
        echo "Usage: $0 <proxy_host> <target_host> [optional_port]"
        exit 1
fi
if [ -z "$2" ]; then
        echo "Usage: $0 <proxy_host> <target_host> [optional_port]"
        exit 1
fi

port=22
if [ "$3" ]; then
    port=$3
fi

proxy_cmd="openssl s_client -quiet -connect $1 -servername $2 -port $port"
echo "Executing: ssh -o ProxyCommand=\"$proxy_cmd\" $2"
ssh -o ProxyCommand="$proxy_cmd" "$2"

# Exit with the status of the last command
exit $?