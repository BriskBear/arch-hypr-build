function setup-hostname() {
  local new_host="$1" 

  echo "$new_host" >> /mnt/etc/hostname
  cat << "EOF" > /mnt/etc/hosts
  127.0.0.1     localhost
  ::1           localhost
  127.0.1.1     $new_host.localdomain   $new_host
EOF
}

function setup-locale() {
  local locale=/mnt/etc/locale.conf 

  sed -i "s/#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/g" "/mnt/etc/locale.gen"
  sed -i "s/#en_US ISO-8859-1/en_US ISO-8859-1/g"   "/mnt/etc/locale.gen"
  
  echo "LANG=en_US.UTF-8"        >> "$locale"
  echo "LC_ALL=\"en_US.UTF-8\""  >> "$locale"
  echo "LC_MESSAGES=en_US.UTF-8" >> "$locale"
  echo "KEYMAP=default" >> /mnt/etc/vconsole.conf

  arch-chroot /mnt locale-gen
}
