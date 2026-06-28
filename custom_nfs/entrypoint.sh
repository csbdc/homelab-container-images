#!/bin/sh
set -e

echo "[NFS] Starting RPC services..."

# RPC bind must start first
rpcbind -w

# Ensure kernel NFS support is mounted
mkdir -p /proc/fs/nfsd
mount -t nfsd nfsd /proc/fs/nfsd 2>/dev/null || true

echo "[NFS] Writing exports..."

cat <<EOF > /etc/exports
/exports *(rw,sync,no_subtree_check,no_root_squash,insecure)
EOF

exportfs -rav

echo "[NFS] Starting NFS daemons..."

# Start kernel NFS server threads
rpc.nfsd 8

# Mount daemon (required for clients)
rpc.mountd -F

# Statd for locking
rpc.statd -F

echo "[NFS] Ready. Serving /exports"

# Keep container alive
tail -f /dev/null