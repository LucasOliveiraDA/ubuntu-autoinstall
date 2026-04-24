#!/bin/bash
set -e

DISK="/dev/nvme0n1p2"

# Montar topo do Btrfs
mkdir -p /mnt
mount -o subvolid=5 $DISK /mnt

# Criar subvolumes
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@cache

# Ajustar fstab
UUID=$(blkid -s UUID -o value $DISK)

cat > /etc/fstab <<EOF
UUID=$UUID / btrfs subvol=@,noatime,compress=zstd:3,ssd,space_cache=v2 0 1
UUID=$UUID /home btrfs subvol=@home,noatime,compress=zstd:3,ssd,space_cache=v2 0 2
UUID=$UUID /var/log btrfs subvol=@log,noatime,compress=zstd:3,ssd,space_cache=v2 0 2
UUID=$UUID /var/cache btrfs subvol=@cache,noatime,compress=zstd:3,ssd,space_cache=v2 0 2
EOF

# Criar diretórios
mkdir -p /home /var/log /var/cache

# GRUB
sed -i 's/GRUB_CMDLINE_LINUX=""/GRUB_CMDLINE_LINUX="rootflags=subvol=@"/' /etc/default/grub
update-grub

# Otimizações
echo "vm.swappiness=10" >> /etc/sysctl.conf

systemctl enable tlp
systemctl enable fstrim.timer

