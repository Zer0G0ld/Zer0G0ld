#!/bin/bash
# Script de instalação automática do Arch Linux - Avalon Edition

set -e

DISK="/dev/sda"
EFI="${DISK}1"
ROOT="${DISK}2"

echo "[+] Particionando o disco..."
sgdisk -Z "$DISK"
sgdisk -n 1:0:+512M -t 1:ef00 "$DISK"
sgdisk -n 2:0:0    -t 2:8300 "$DISK"

echo "[+] Formatando partições..."
mkfs.fat -F32 "$EFI"
mkfs.ext4 "$ROOT"

echo "[+] Montando partições..."
mount "$ROOT" /mnt
mkdir -p /mnt/boot
mount "$EFI" /mnt/boot

echo "[+] Instalando pacotes base..."
pacstrap -K /mnt base linux linux-firmware vim nano networkmanager systemd-boot

echo "[+] Gerando fstab..."
genfstab -U /mnt >> /mnt/etc/fstab

echo "[+] Entrando no sistema..."
arch-chroot /mnt /bin/bash <<EOF

ln -sf /usr/share/zoneinfo/America/Sao_Paulo /etc/localtime
hwclock --systohc

echo "Configurando locale..."
sed -i 's/^#pt_BR.UTF-8/pt_BR.UTF-8/' /etc/locale.gen
locale-gen
echo "LANG=pt_BR.UTF-8" > /etc/locale.conf

echo "avalon" > /etc/hostname

cat > /etc/hosts << EOH
127.0.0.1   localhost
::1         localhost
127.0.1.1   avalon.localdomain avalon
EOH

echo "Defina a senha root:"
echo root:123456 | chpasswd

echo "[+] Habilitando NetworkManager..."
systemctl enable NetworkManager

echo "[+] Instalando systemd-boot..."
bootctl install

cat > /boot/loader/entries/arch.conf << EOL
title   Avalon Linux
linux   /vmlinuz-linux
initrd  /initramfs-linux.img
options root=${ROOT} rw
EOL

echo "default arch.conf" > /boot/loader/loader.conf

EOF

echo "[+] Instalação concluída! Pronto para reboot."
