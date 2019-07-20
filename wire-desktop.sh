#!/usr/bin/env bash
NAME=docker-wire
DIR="$( cd "$( dirname "$(readlink ${BASH_SOURCE[0]})" )" ><(:) && pwd -P )"
MAIN () {
	# Run daemon
	pidof dockerd &><(:) || sudo systemctl start docker &><(:)
	# Build && re-build quietly echoing ID
	sudo docker build --build-arg=PKGS="wire-desktop" -t "${NAME}" "${DIR}" || return $?
	local IMAGE=$(sudo docker build -q --build-arg=PKGS="wire-desktop" -t "${NAME}" "${DIR}" ) || return $?
	[ "${IMAGE}x" = "x" ] && return 1
	# This will be mounted on $HOME and holds session stuff
	local VOL=$(sudo docker volume create "${NAME}") || return $?
	local RHOME='/home/system'
	# Define arguments
	local -a ARGV=(
		--name "${NAME}"
		--hostname "$(hostname)"
		--device /dev/snd/
		-v "${VOL}:${RHOME}"
		-v /tmp/.X11-unix:/tmp/.X11-unix:ro
		-v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket:ro
		-v /run/user/$UID/pulse/native:/run/user/1000/pulseaudio
		--mount type=bind,src="${XAUTHORITY}",dst="${RHOME}/.Xauthority",readonly
		--ipc="host"
	)
	# Share ~/Downloads
	DOWNLOADS="$( cd $(dirname ${XAUTHORITY}) ; pwd )/Downloads"
	if [ -d "${DOWNLOADS}" ]; then
		ARGV=("${ARGV[@]}" --mount type=bind,src="${DOWNLOADS}",dst="${RHOME}/Downloads")
		printf '+%s\n' "${DOWNLOADS}"
	fi
	# Refresh container
	sudo docker kill "${NAME}" 2><(:)
	sudo docker rm "${NAME}" 2><(:)
	_CMD=$(echo sudo docker run --rm -d "${ARGV[@]}" "${IMAGE}" "wire-desktop")
	echo $_CMD
	$_CMD
}
MAIN
