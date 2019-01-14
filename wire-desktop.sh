#!/bin/sh
# ln -s ${PWD}/wire-desktop.sh /usr/local/bin/wire-desktop
# chmod +x ${PWD}/wire-desktop.sh
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
	DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"
	SOURCE="$(readlink "$SOURCE")"
	[[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" >/dev/null 2>&1 && pwd )"

if [ -s "${HOME}/.Xauthority" ]; then
	xauth="${HOME}/.Xauthority"
elif [ -s "/home/${SUDO_USER}/.Xauthority" ]; then
	xauth="/home/${SUDO_USER}/.Xauthority"
else
        echo ".Xauthority not found"
        exit
fi
shared="${xauth%\/*}/Downloads"
RUNAS="$(stat -c '%u:%g' ${shared})"
AUDIOGID="$(getent group audio | tr -d x:audio)"
if [ -z "${RUNAS}" ]; then
	echo "No shareable ~/Downloads dir found for ${xauth} owner"
	exit
fi
if [ ! -z "${AUDIOGID##[0-9]*}" ]; then
	echo "Could not determine gid of local audio group"
	exit
fi

running="$(sudo docker ps -q --filter 'name=alpine-wire-desktop')"
if [ "${running}" != "" ]; then
	sudo docker kill "${running}"
fi


mkdir -pv "${DIR}/appdata/"{tmp,stdstreams,Downloads,cov}
cp "${xauth}" "${DIR}/appdata"
chown -R "${RUNAS}" "${DIR}/appdata"

pidof dockerd || systemctl start docker

sudo docker build \
	--compress \
	--force-rm \
	--build-arg "RUNAS=${RUNAS}" \
	--build-arg "AUDIOGID=${AUDIOGID}" \
	-t alpine-wire-desktop:latest "${DIR}" &&\
sudo docker run -d --rm \
	--name alpine-wire-desktop \
	-v /tmp/.X11-unix:/tmp/.X11-unix:ro \
	-v /var/run/dbus/system_bus_socket:/var/run/dbus/system_bus_socket:ro \
	--mount src="${DIR}/appdata",target=/appdata,type=bind \
	--mount src="${shared}",target=/appdata/Downloads,type=bind \
	--hostname "$(hostname)" \
	--device /dev/snd/ \
	--ipc="host" \
	alpine-wire-desktop
