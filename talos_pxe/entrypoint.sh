#!/bin/sh
dnsmasq --conf-file=/etc/dnsmasq.d/dnsmasq.conf -k &
nginx -g "daemon off;" 2>&1 | tee /proc/1/fd/1
