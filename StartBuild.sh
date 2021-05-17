#!/usr/bin/env bash

if [ ! -e ./config.cfg ]; then
	echo 'ERROR: config.cfg is missing. This file is used to configure the connectivity between the embedded device and the server. Please copy config.cfg.sample in config.cfg and adapt the configuration to your network setup.'
else
	DOCKER_NETWORK_NAME="$(docker network ls --format '{{.Name}}' | grep fmu_network)"

	if [ -z "$DOCKER_NETWORK_NAME" ]; then
		echo "fmu_network does not seem to exists. Did you run StartServer.sh?"
		exit 1
	fi
	# Check if we are running on Linux or Windows to adapt the path of the source command
	unamestr=`uname`
	if [[ "$unamestr" == 'Linux' ]]; then
		# Check if we are running inside builbot worker to disable --interractive
		if [ -n "$BUILDMASTER" ]; then
			docker run \
			--volume $(pwd)/build:/data \
			--volume $(pwd)/yocto-entrypoint.sh:/yocto-entrypoint.sh \
			--volume ~/.gitconfig:/home/docker/.gitconfig \
			--volume $(pwd)/config.cfg:/home/docker/config.cfg \
			--network "$DOCKER_NETWORK_NAME" --tty --rm fullmetalupdate/build-yocto:v2.0  \
			yocto $@
		else
			docker run \
			--volume $(pwd)/build:/data \
			--volume $(pwd)/yocto-entrypoint.sh:/yocto-entrypoint.sh \
			--volume ~/.gitconfig:/home/docker/.gitconfig \
			--volume $(pwd)/config.cfg:/home/docker/config.cfg \
			--interactive --network "$DOCKER_NETWORK_NAME" --tty --rm fullmetalupdate/build-yocto:v2.0  \
			yocto $@
		fi
	else
		# Check if we are running inside builbot worker to disable --interractive
		if [ -n "$BUILDMASTER" ]; then
			docker volume create yocto_fullmetalupdate
			MSYS_NO_PATHCONV=1 docker run \
			--volume yocto_fullmetalupdate:/data \
			--volume $(pwd)/yocto-entrypoint.sh:/yocto-entrypoint.sh \
			--volume ~/.gitconfig:/home/docker/.gitconfig \
			--volume $(pwd)/config.cfg:/home/docker/config.cfg \
			--network "$DOCKER_NETWORK_NAME" --tty --rm fullmetalupdate/build-yocto:v2.0  \
			yocto $@
		else
			docker volume create yocto_fullmetalupdate
			MSYS_NO_PATHCONV=1 docker run \
			--volume yocto_fullmetalupdate:/data \
			--volume $(pwd)/yocto-entrypoint.sh:/yocto-entrypoint.sh \
			--volume ~/.gitconfig:/home/docker/.gitconfig \
			--volume $(pwd)/config.cfg:/home/docker/config.cfg \
			--interactive --network "$DOCKER_NETWORK_NAME" --tty --rm fullmetalupdate/build-yocto:v2.0  \
			yocto $@
		fi
	fi

fi
