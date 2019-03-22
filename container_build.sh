#!/usr/bin/env sh

if ! command -v id > /dev/null 2>&1; then
	echo "Please install id, Bye!"
	exit 1
fi

docker build \
	--build-arg PUID="$(id -u)" \
	-t fullmetalupdate_build_yocto \
	https://github.com/FullMetalUpdate/dockerfiles.git#:yocto
