#!/usr/bin/env bash

SUPPORTED_MACHINES=" \
  imx6qdlsabresd \
  raspberrypi \
"
SUPPORTED_YOCTO=" \
  rocko
"
SUPPORTED_FULLMETALUPATE=" \
  latest-release \
  v1.0 \
"

yocto_sync()
{
  local MACHINE="$1"
  local YOCTO="$2"
  local FULLMETALUPDATE="$3"

  sudo mkdir -p "${DATADIR}/yocto/"
  sudo chown docker:docker "${DATADIR}/yocto/"
  cd "${DATADIR}/yocto"

  echo "N" | repo init -u https://github.com/FullMetalUpdate/manifest -b "${YOCTO}/${MACHINE}" -m "${FULLMETALUPDATE}.xml"

  repo sync --force-sync
}

is_in_list()
{
  local key="$1"
  local list="$2"

  for item in $list; do
    if [ "$item" = "$key" ]; then
      return 0
    fi
  done

  return 1
}

is_machine_supported()
{
  local MACHINE="$1"

  is_in_list "$MACHINE" "$SUPPORTED_MACHINES"
}

is_yocto_supported()
{
  local YOCTO="$1"

  is_in_list "$YOCTO" "$SUPPORTED_YOCTO"
}

is_fullmetalupdate_supported()
{
  local FULLMETALUPDATE="$1"

  is_in_list "$FULLMETALUPDATE" "$SUPPORTED_FULLMETALUPATE"
}

main()
{
  if [ $# -lt 1 ]; then
    echo "Not enough argument"
    exit 1
  fi

  if [ ! -d "${DATADIR}/yocto/sources" ] && [ "$1" != "sync" ]; then
    echo "yocto/sources does not exists: use the command 'sync <machine> <yocto_version> <fullmetalupdate_version>', Bye!"
    exit 1
  fi


  case "$1" in
    all)
      cd "${DATADIR}/yocto"
      TEMPLATECONF=$PWD/sources/meta-fullmetalupdate-extra/conf/imx6qdlsabresd
      source sources/poky/oe-init-build-env build
      DISTRO=fullmetalupdate-containers bitbake fullmetalupdate-containers-package -k
      DISTRO=fullmetalupdate-os bitbake fullmetalupdate-os-package -k
      ;;

    sync)
      shift; set -- "$@"
      if [ $# -ne 3 ]; then
        echo "sync command accepts only 3 arguments"
        exit 1
      fi

      if ! is_machine_supported "$1"; then
        echo "$1 is not a supported machine: $SUPPORTED_MACHINES"
        exit 1
      fi

      if ! is_yocto_supported "$2"; then
        echo "$2 is not a supported yocto version: $SUPPORTED_YOCTO"
        exit 1
      fi

      if ! is_fullmetalupdate_supported "$3"; then
        echo "$3 is not a supported version: $SUPPORTED_FULLMETALUPATE"
        exit 1
      fi

      yocto_sync $@

      cd "${DATADIR}/yocto"
      export TEMPLATECONF=$PWD/sources/meta-fullmetalupdate-extra/conf/$1
      cp -v $TEMPLATECONF/* $PWD/sources/meta-fullmetalupdate-extra/conf/
      source sources/poky/oe-init-build-env build
      ;;

    fullmetalupdate-containers)
      cd "${DATADIR}/yocto"
      source sources/poky/oe-init-build-env build
      DISTRO=fullmetalupdate-containers bitbake fullmetalupdate-containers-package -k
      ;;

    fullmetalupdate-os)
      cd "${DATADIR}/yocto"
      source sources/poky/oe-init-build-env build
      if [ ! -d "${DATADIR}/yocto/build/tmp/fullmetalupdate-containers/deploy/containers" ]; then
        DISTRO=fullmetalupdate-containers bitbake fullmetalupdate-containers-package -k
      fi
      DISTRO=fullmetalupdate-os bitbake fullmetalupdate-os-package -k
      ;;
    
    build-container)
      shift; set -- "$@"
      if [ $# -ne 1 ]; then
        echo "build-container command accepts only 1 argument"
        exit 1
      fi
      cd "${DATADIR}/yocto"
      source sources/poky/oe-init-build-env build
      DISTRO=fullmetalupdate-containers bitbake $1 -k
      ;;

    package-wic)
      cd "${DATADIR}/yocto"
      source sources/poky/oe-init-build-env build
      DISTRO=fullmetalupdate-os bitbake fullmetalupdate-os-package -c image_wic -f
      DISTRO=fullmetalupdate-os bitbake fullmetalupdate-os-package -k
      ;;

    bash)
      cd "${DATADIR}/yocto"
      source sources/poky/oe-init-build-env build
      bash
      ;;
    *)
      echo "Command not supported: $1, bye!"
      exit 1
  esac

}

main $@
