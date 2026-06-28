#!/bin/sh
set -eux

echo "[nfs] starting"

mkdir -p /proc/fs/nfsd

mountpoint -q /proc/fs/nfsd || mount -t nfsd nfsd /proc/fs/nfsd

echo "[nfs] starting kernel nfsd FIRST"

rpc.nfsd 8

# small delay to ensure kernel threads are registered
sleep 1

echo "[nfs] writing exports"

cat > /etc/exports <<EOF
/srv/nfs *(rw,sync,no_subtree_check,no_root_squash,fsid=0)
EOF

exportfs -rav

echo "[nfs] ready"

exec dmesg -w