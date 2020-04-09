sed_escape() {
  sed -e 's/[]\/$*.^[]/\\&/g'
}

cfg_write() { # path, key, value
  cfg_delete "$1" "$2"
  echo "$2 = $3" >> "$1"
}

cfg_delete() { # path, key
  test -f "$1" && sed -i "/^$(echo $2 | sed_escape).*$/d" "$1"
}

if [ -e ./config.cfg ]; then
	echo 'config.cfg already exits. Do you really want to overwrite it? Please type yes to confirm.'
    read -n 3 -p "> " ans;

    case $ans in
        'yes')
        ;;
        *)
            exit;;
    esac
fi

cp ./config.cfg.sample ./config.cfg

if [ -n "$FMU_CLOUD_HOSTNAME" ]; then
  # Check if FMU_CLOUD_HOSTNAME env variable is defined: 
  # that means that we are running inside buildbot worker container
  cfg_write config.cfg server_host_name "$FMU_CLOUD_HOSTNAME".local
  echo "Wrote server_host_name $FMU_CLOUD_HOSTNAME.local in config.cfg from FMU_CLOUD_HOSTNAME env variable"
else
  cfg_write config.cfg server_host_name $(hostname).local
  echo "Wrote server_host_name $(hostname).local in config.cfg from hostname command"
fi 