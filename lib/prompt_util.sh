function confirm() {
  local query="$@" 

  printf "${query} (\e[38;5;185my\e[0m/\e[38;5;1mn\e[0m) "
  read

  case $REPLY in
    y|Y)
      exit 0
      ;;
    n|N)
      exit 1
      ;;
    *)
      exit 2
      ;;
  esac
}


function default() {
  local default="$2"
  local prompt="$1"
  unset REPLY

  read -p "$prompt ${default}: "

  if [[ -z $REPLY ]]
  then export choice=$default
  else export choice=$REPLY
  fi
}


function save-cursor() {
  printf "\e[s"
}


function restore-cursor() {
  printf "\e[u\e[0J"
}
