#!/usr/bin/env bash

. lib/prompt_util.sh

function set-password() {
  local user="$1"

  restore-cursor
  printf "Please set ${user}'s password.\n"
  arch-chroot /mnt passwd $user
  restore-cursor
  printf "\e[1mPasswordSet:\e[0m \e[38;5;208m${user}\e[0m\n"
  save-cursor
}
