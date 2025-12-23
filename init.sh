#!/usr/bin/env bash

st -e pacman-key --init
st -e pacman-key --populate archlinux
st -e pacman -Sy --noconfirm \
  archlinux-keyring          \
  arch-install-scripts       \
  btrfs-progs                \
  dosfstools                 \
  lvm2                       \
  vim
alias :e='vim'
alias setup='pacman -S --noconfirm'
