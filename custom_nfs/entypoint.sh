#!/bin/sh
set -eu

echo "[nfs] starting nfs-v4 server"

# Ensure required filesystem exists
mkdir -p /proc/fs/nfsd

# Mount the kernel nfsd filesystem (required for all kernel NFS servers)
mountpoint -q /proc/fs/nfsd || mount -t nfsd nfsd /proc/fs/nfsd

# Create export config
cat > /etc/exports <<EOF
/srv/nfs *(rw,sync,no_subtree_check,no_root_squash,fsid=0)
EOF

# Apply exports
exportfs -ra

# Start kernel nfs server threads
# (this is what actually serves NFS traffic)
rpc.nfsd 8

echo "[nfs] nfsd started"

# Keep container alive + reapply exports if needed
# (rpc.nfsd runs in background so we just idle here)
tail -f /dev/null