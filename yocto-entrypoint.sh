#!/usr/bin/env bash

SUPPORTED_MACHINES_ROCKO=" \
  imx6qdlsabresd \
  raspberrypi3 \
"
SUPPORTED_MACHINES_THUD=" \
  imx8mqevk \
  stm32mp1-disco \
"
SUPPORTED_MACHINES_WARRIOR=" \
  imx8mqevk \
"

SUPPORTED_FULLMETALUPATE=" \
  dev \
  latest-release \
"

yocto_sync()
{
  local MACHINE="$1"
  local YOCTO="$2"
  local FULLMETALUPDATE="$3"

  sudo mkdir -p "${DATADIR}/yocto/"
  sudo chown docker:docker "${DATADIR}/yocto/"
  cd "${DATADIR}/yocto"

  case "${MACHINE}" in
  "imx8mqevk")
      BRANCH_REPO="imx"
      ;;
  "imx6qdlsabresd")
      BRANCH_REPO="imx"
      ;;
  "raspberrypi3")
      BRANCH_REPO="raspberrypi"
      ;;
  "stm32mp1-disco")
      BRANCH_REPO="stm32mp1"
      ;;
  *)
      return 1
      ;;
  esac

  echo "N" | repo init -u https://github.com/FullMetalUpdate/manifest -b "${YOCTO}/${BRANCH_REPO}" -m "${FULLMETALUPDATE}.xml"

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

is_yocto_supported()
{
  local MACHINE="$1"
  local YOCTO="$2"
  case "${YOCTO}" in
  "rocko")
      if ! is_in_list "$MACHINE" "$SUPPORTED_MACHINES_ROCKO"; then
        echo "$MACHINE is not supported by FullMetalUpdate by the Yocto version of Rocko: $SUPPORTED_MACHINES_ROCKO"
      fi
      ;;
  "thud")
      if ! is_in_list "$MACHINE" "$SUPPORTED_MACHINES_THUD"; then
        echo "$MACHINE is not supported by FullMetalUpdate for the Yocto version of Thud: $SUPPORTED_MACHINES_THUD"
      fi
      ;;
  "warrior")
      if ! is_in_list "$MACHINE" "$SUPPORTED_MACHINES_WARRIOR"; then
        echo "$MACHINE is not supported by FullMetalUpdate for the Yocto version of Warrior: $SUPPORTED_MACHINES_WARRIOR"
      fi
      ;;
  *)
      return 1
      ;;
  esac

}

is_fullmetalupdate_supported()
{
  local FULLMETALUPDATE="$1"

  is_in_list "$FULLMETALUPDATE" "$SUPPORTED_FULLMETALUPATE"
}

show_usage()
{
  echo "Usage: StartBuild.sh command [args]"
  echo "Commands:"
  echo "    sync <machine> <yocto_version> <FullMetalUpdate_version>"
  echo "        Sync Yocto and Full Metal Update versions"
  echo "        E.g. sync imx6qdlsabresd rocko v1.0"
  echo
  echo "    all"
  echo "        Build Full Metal Update OS and containers images"
  echo
  echo "    fullmetalupdate-containers"
  echo "        Build Full Metal Update containers image"
  echo
  echo "    fullmetalupdate-os"
  echo "        Build Full Metal Update OS image"
  echo
  echo "    build-container <image>"
  echo "        Build Full Metal Update container image <image>"
  echo
  echo "    package-wic"
  echo "        Build the .wic SD Card image"
  echo
  echo "    bash [distro]"
  echo "        Start an interactive bash shell in the build container"
  echo "        Optional: [distro] to use"
  echo "            E.g. fullmetalupdate-os, fullmetalupdate-containers"
  echo
  echo "    help"
  echo "        Show this text"
  echo
  exit 1
}

main()
{
  if [ $# -lt 1 ]; then
    show_usage
  fi

  if [ ! -d "${DATADIR}/yocto/sources" ] && [ "$1" != "sync" ]; then
    echo "The directory 'yocto/sources' does not yet exist. Use the 'sync' command"
    show_usage
  fi


  case "$1" in
    all)
      cat /home/docker/config.cfg
      cd "${DATADIR}/yocto"
      TEMPLATECONF=$PWD/sources/meta-fullmetalupdate-extra/conf/$1
      source sources/poky/oe-init-build-env build
      DISTRO=fullmetalupdate-containers bitbake fullmetalupdate-containers-package -k
      DISTRO=fullmetalupdate-os bitbake fullmetalupdate-os-package -k
      ;;

    sync)
      shift; set -- "$@"
      if [ $# -ne 3 ]; then
        echo "sync command accepts only 3 arguments"
        show_usage
      fi

      if ! is_yocto_supported "$1" "$2"; then
        echo "$2 is not a supported yocto version: $SUPPORTED_YOCTO"
        show_usage
      fi

      if ! is_fullmetalupdate_supported "$3"; then
        echo "$3 is not a supported version: $SUPPORTED_FULLMETALUPATE"
        show_usage
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
        show_usage
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

      if [ ! -z $2 ]; then
        DISTRO=$2 bash
      else
        bash
      fi
      ;;

    help)
      show_usage
      ;;

    *)
      echo "Command not supported: $1"
      show_usage
  esac

}

main $@
