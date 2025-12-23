#!/usr/bin/env bash

. lib/locale.sh
. lib/prompt_util.sh
. lib/sanitize.sh
. lib/select_disk.sh

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
# TODO: Expand to allow extended partitions
command=`sed -e s/EFISIZE/$EFI_SIZE/g -e s/PRIMARY/+/g ref/sfdisk`
echo -e "$command" | sfdisk $DISK_TARGET

# Set the encryption password and encrypt volume
cryptsetup --use-random luksFormat ${DISK_TARGET}2
cryptsetup open ${DISK_TARGET}2 rute

# Create+Map luks volume
pvcreate /dev/mapper/rute
vgcreate vg0 /dev/mapper/rute

# Create root partition in luksvolume
lvcreate -l '100%FREE' vg0 -n ROOT

# Format BOOT and '/' partitions
mkfs.fat -F 32 -n 'BOOT' ${DISK_TARGET}1
mkfs.btrfs -L \/ /dev/vg0/ROOT

# Mount the Target Partitions
mount /dev/vg0/ROOT /mnt
mkdir /mnt/boot
mount -L BOOT /mnt/boot

## Install linux image ##
# Install archlinux to /mnt with the packages in ref/packages
pacstrap -P /mnt `tr '\n' ' ' < ref/packages`

# Ensure /mnt/etc exists and generate fstab
mkdir -pv /mnt/etc
genfstab -U -p /mnt > /mnt/etc/fstab

timedatectl set-ntp true  # Ensure NTP

# Add decrypt boot hooks
# sed -i '/HOOKS=/s/)/ encrypt lvm2)/g' /mnt/etc/mkinitcpio.conf
BOOT_HOOKS=`cat ref/hooks.list`
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

# Allow wheel nopasswd
sed -i '/NOPASSWD/s/# //g' /mnt/etc/sudoers

# Set root password
restore-cursor
printf "Please set a root password.\n"
arch-chroot /mnt passwd
restore-cursor
printf "\e[1mPasswordSet:\e[0m \e[38;5;208mroot\e[0m\n"
save-cursor

# Optionally customize wheel-user name
default "Name wheel-user?" dev
restore-cursor
WHEEL_USER=$choice
printf "\e[1mWheelUser:\e[0m \e[38;5;208m$WHEEL_USER\e[0m\n"
save-cursor

# Create wheel-user
arch-chroot /mnt useradd -m -g users -G adm,audio,network,video,wheel $WHEEL_USER

# Set wheel-user's password
printf "Please set ${WHEEL_USER}'s password.\n"
arch-chroot /mnt $WHEEL_USER
restore-cursor
printf "\e[1mPasswordSet:\e[0m \e[38;5;208m$WHEEL_USER\e[0m\n"
save-cursor
