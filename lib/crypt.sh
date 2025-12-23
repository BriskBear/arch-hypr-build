#!/usr/bin/env bash

## Format the disk and setup disk encryption ##
function crypt-setup() {
  local size="$1"
  local target="$2"
  
  # TODO: Expand to allow extended partitions
  command=`sed -e s/EFISIZE/${size}/g -e s/PRIMARY/+/g ref/sfdisk`
  echo -e "$command" | sfdisk ${target}

  # Set the encryption password and encrypt volume
  cryptsetup --use-random luksFormat ${target}2
  cryptsetup open ${target}2 rute
  
  # Create+Map luks volume
  pvcreate /dev/mapper/rute
  vgcreate vg0 /dev/mapper/rute
  
  # Create root partition in luksvolume
  lvcreate -l '100%FREE' vg0 -n ROOT
  
  # Format BOOT and '/' partitions
  mkfs.fat -F 32 -n 'BOOT' ${target}1
  mkfs.btrfs -L \/ /dev/vg0/ROOT
  
  # Mount the Target Partitions
  mount /dev/vg0/ROOT /mnt
  mkdir /mnt/boot
  mount -L BOOT /mnt/boot
}
