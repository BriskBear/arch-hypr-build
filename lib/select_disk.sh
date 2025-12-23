function select-disk() {
  local disks=(`fdisk -l | grep 'Disk /' | awk -F' |:' '{print $2}'`)

  show-disks

  for ((ddx = 0; ddx < ${#disks[@]}; ddx++))
  do
    echo "$((ddx + 1)): ${disks[$ddx]}"
  done

  printf "\e[1mSelect a disk: \e[0m"
  read

  export DISK_TARGET=${disks[$((REPLY - 1))]}
}


function show-disks() {
  lsblk -o NAME,LABEL,SIZE,FSTYPE,TYPE,MOUNTPOINT,UUID
}
