#!/usr/bin/env bash

function prep-skel() {
  local FILES=(.bashrc .local/etc/profile .local/etc/profile.d/environment.sh)

  cp -r ~/.local /mnt/etc/skel/
  sed -i "s/--i-am-really-stupid//g" ~/.bashrc >> /mnt/etc/skel/.bashrc
  cp ~/.bashrc /mnt/etc/skel/
  ln -sf .bashrc /mnt/etc/skel/.bash_profile
  cp /usr/local/bin/* /mnt/usr/local/bin/
  mkdir /mnt/etc/skel/.local/bin
  rm /mnt/usr/local/bin/zen

  for file in ${FILES[@]}
  do replace-root "$file"
  done
}

function replace-root() {
  local file
  local lead="/mnt/etc/skel"

  sed -i 's|/root|$HOME|g' "${lead}/${file}"
}
