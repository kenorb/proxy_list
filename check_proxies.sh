#!/usr/bin/env bash
# Script to check availability of public proxies.
[ $# -eq 0 ] && { echo "Usage: $0 file"; exit 1; }
file="$1"
ip_url="ifconfig.co"
cat $file | egrep -o '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}:[0-9]{1,5}' | \
  while IFS=: read ip port; do
    (
      (timeout 2 curl -x socks5://$ip:$port -qs -o/dev/null http://example.com/ && printf "socks5\t$ip\t$port\n") \
      || (timeout 2 curl -x socks4://$ip:$port -qs -o/dev/null http://example.com/ && printf "socks4\t$ip\t$port\n") \
      || (timeout 2 curl -x http://$ip:$port -qs -o/dev/null http://example.com/ && printf "http\t$ip\t$port\n")
    ) &
    sleep 0.2
  done
sleep 2
wait
