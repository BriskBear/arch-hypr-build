function part-size() {
  local size="$1"

  if [[ $size =~ [0-9]+M ]]
  then printf $size
  else printf "${size}M"
  fi
}
