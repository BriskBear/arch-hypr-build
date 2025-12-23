#!/usr/bin/env bash

. lib/crypt.sh
. lib/locale.sh
. lib/password.sh
. lib/prompt_util.sh
. lib/sanitize.sh
. lib/select_disk.sh

BOOT_HOOKS=`cat ref/hooks.list`
DISK_TARGET=
EFI_SIZE=
NEW_HOST=
WHEEL_USER=

save-cursor

# Set DISK_TARGET
select-disk

restore-cursor
printf "\e[1mTargetDisk:\e[0m \e[38;5;208m$DISK_TARGET\e[0m\n"
save-cursor

# Optionally customize EFI partition size
default "Custom EFI size?" 1024M
restore-cursor
EFI_SIZE=$(part-size $choice)
printf "\e[1mEFISize:\e[0m \e[38;5;208m$EFI_SIZE\e[0m\n"
save-cursor

# Optionally set the new hostname
default "Set new Hostname?" dummy
restore-cursor
NEW_HOST=$choice
printf "\e[1mNewHostname:\e[0m \e[38;5;208m$NEW_HOST\e[0m\n"
save-cursor

## Format the disk and setup disk encryption ##
crypt-setup $EFI_SIZE $DISK_TARGET
restore-cursor
printf "\e[1mDriveEncryptionSet:\e[0m \e[38;5;208m${DISK_TARGET}2\e[0m\n"
save-cursor

## Install linux image ##
# Install archlinux to /mnt with the packages in ref/packages
pacstrap -P /mnt `tr '\n' ' ' < ref/packages`

# Ensure /mnt/etc exists and generate fstab
mkdir -pv /mnt/etc
genfstab -U -p /mnt > /mnt/etc/fstab

timedatectl set-ntp true  # Ensure NTP

# Add decrypt boot hooks
sed -ie "/^HOOKS=/s/HOOKS=.*/$BOOT_HOOKS/g" /mnt/etc/mkinitcpio.conf

# Initialize systemd-boot
arch-chroot /mnt systemd-machine-id-setup
arch-chroot /mnt bootctl --path=/boot install
uuid=$(blkid --match-tag UUID -o value /dev/vda2)

# Configure systemd-boot
sed "/FOUND/s/FOUND/$uuid/g" ref/entry.conf > /mnt/boot/loader/entries/arch.conf
cp -v ref/loader.conf /mnt/boot/loader/
setup-hostname "$NEW_HOST"
setup-locale

# Prepare /etc/skel - new user default directories
cp -r ~/.local /mnt/etc/skel/
sed -i "s/--i-am-really-stupid//g" ~/.bashrc >> /mnt/etc/skel/.bashrc
cp ~/.bashrc /mnt/etc/skel/
ln -sf .bashrc /mnt/etc/skel/.bash_profile
cp /usr/local/bin/st /mnt/usr/local/bin/

restore-cursor
printf "\e[1mArchlinuxInstalled:\e[0m \e[38;5;208m${DISK_TARGET}2\e[0m\n"
save-cursor

# Allow wheel nopasswd
sed -i '/NOPASSWD/s/# //g' /mnt/etc/sudoers

# Set root password
set-password root

# Optionally customize wheel-user name
default "Name wheel-user?" dev
restore-cursor
WHEEL_USER=$choice
printf "\e[1mWheelUser:\e[0m \e[38;5;208m$WHEEL_USER\e[0m\n"
save-cursor

# Create wheel-user
arch-chroot /mnt useradd -m -g users -G adm,audio,network,video,wheel $WHEEL_USER

# Set wheel-user's password
set-password $WHEEL_USER

# Re-initialize mkinitcpio
arch-chroot /mnt mkinitcpio -P
