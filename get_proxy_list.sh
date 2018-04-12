#!/usr/bin/env bash
# Script to fetch list of socks proxies from free online resources.
set -e
type pup jq bc seq > /dev/null

socks_file="proxy_list_socks.txt"
socks4_file="proxy_list_socks4.txt"
socks5_file="proxy_list_socks5.txt"

# socks-proxy.net
paste -d: \
  <(pup -f <(curl -sL https://www.socks-proxy.net/) '#proxylisttable tr td:nth-child(1) text{}') \
  <(pup -f <(curl -sL https://www.socks-proxy.net/) '#proxylisttable tr td:nth-child(2) text{}')

# my-proxy.com (socks4)
pup -f <(curl -sL http://www.my-proxy.com/free-socks-4-proxy.html) ".list text{}" \
  | awk -F# '{print $1}' \
  | tee "$socks4_file"

# my-proxy.com (socks5)
pup -f <(curl -sL http://www.my-proxy.com/free-socks-5-proxy.html) ".list text{}" \
  | awk -F# '{print $1}' \
  | tee "$socks5_file"

# xroxy.com (socks)
for i in {1..20}; do
  curl -s "http://www.xroxy.com/proxylist.php?port=&type=All_socks&ssl=&country=&latency=&reliability=&sort=reliability&desc=true&pnum=${i}" -A Mozilla | grep 'proxy:name' | awk -F"host=|&port=|&isSocks" '{print $2":"$3}'
done \
  | tee "$socks_file"

# gatherproxy.com (sockslist)
pup -f <(curl -sL 'http://www.gatherproxy.com/sockslist') "script text{}" \
  | paste -d: - - \
  | egrep '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' \
  | grep -o "'[^']\+'" \
  | paste -d: - - \
  | tr -d "'" \
  | tee "$socks_file"

# gatherproxy.com (anonymity)
curl -sL "http://www.gatherproxy.com/proxylist/anonymity/?t=Transparent" \
  | grep -o "{.*PROXY_IP[^}]\+}" \
  | jq ".PROXY_IP,.PROXY_PORT" \
  | paste - - \
  | while read ip port; do
      eval ip=$ip port=$port
      printf "%s:%s\n" $ip $(bc <<<$"ibase=16; $port")
    done \
  | tee "$socks_file"

# gatherproxy.com (anonymity)
pager="$(curl -sL -d "Type=transparent&PageIdx=1" "http://www.gatherproxy.com/proxylist/anonymity/?t=Transparent" | grep gp.pageClick | wc -l)"
for page in $(seq 1 $pager); do
  curl -sL -d "Type=transparent&PageIdx=$page" "http://www.gatherproxy.com/proxylist/anonymity/?t=Transparent" \
    | pup "script text{}" \
    | grep document.write \
    | grep -o "'[^']\+'" \
    | paste - - \
    | while read ip port; do
        eval ip=$ip port=$port
        printf "%s:%s\n" $ip $(bc <<<$"ibase=16; $port")
      done
done \
  | tee "$socks_file"
