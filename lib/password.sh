#!/usr/bin/env bash

. prompt_util.sh

function set-password() {
  local user

  restore-cursor
  printf "Please set ${user}'s password.\n"
  arch-chroot /mnt passwd $user
  restore-cursor
  printf "\e[1mPasswordSet:\e[0m \e[38;5;208m${user}\e[0m\n"
  save-cursor
}
