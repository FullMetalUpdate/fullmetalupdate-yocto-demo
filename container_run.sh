#!/usr/bin/env sh

if [ ! -e ./config.cfg ]; then
	echo 'ERROR: config.cfg is missing. This file is used to configure the connectivity between the embedded device and the server. Please copy config.cfg.sample in config.cfg and adapt the configuration to your network setup.'
else
	DOCKER_NETWORK_NAME="$(docker network ls --format '{{.Name}}' | grep fmu_network)"

	if [ -z "$DOCKER_NETWORK_NAME" ]; then
		echo "fmu_network does not seem to exists. Did you run ./RunWiUpdate.sh?"
		exit 1
	fi

	docker run \
		--volume $(pwd)/build:/data \
		--volume $(pwd)/yocto-entrypoint.sh:/yocto-entrypoint.sh \
		--volume ~/.gitconfig:/home/docker/.gitconfig \
		--volume ~/.ssh/id_rsa_bitbucket:/home/docker/.ssh/id_rsa \
		--volume $(pwd)/config.cfg:/home/docker/config.cfg \
		--interactive --network "$DOCKER_NETWORK_NAME" --tty --rm wi_update_yocto \
		yocto $@
fi
