FROM alpine:latest
WORKDIR /tmp

ARG RUNAS
ARG AUDIOGID

RUN echo $'-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\ny70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\ntOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\nm2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\nKXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\nZvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\n1QIDAQAB\n-----END PUBLIC KEY-----' > /etc/apk/keys/sgerrand.rsa.pub &&\
	latest="$(wget -qO- https://github.com/sgerrand/alpine-pkg-glibc/releases | grep -o '[0-9]\.[0-9]\{2\}\-r[0-9]' | head -n 1)" &&\
	wget -qO glibc.apk "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/unreleased/glibc-${latest}.apk" &&\
	wget -qO glibc-bin.apk "https://github.com/sgerrand/alpine-pkg-glibc/releases/download/unreleased/glibc-bin-${latest}.apk" &&\
	apk add --no-cache \
		./glibc.apk \
		./glibc-bin.apk \
		binutils \
		font-noto \
		gtk+2.0 \
		gtk+3.0 \
		libxscrnsaver \
		pulseaudio \
		nss \
		gconf \
	&& \
	wget -qO alsa-lib.tar.xz https://www.archlinux.org/packages/extra/x86_64/alsa-lib/download/ && unxz alsa-lib.tar.xz && tar -C / -xf alsa-lib.tar && rm alsa-lib.tar &&\
	wget -qO graphite.tar.xz https://www.archlinux.org/packages/extra/x86_64/graphite/download/ && unxz graphite.tar.xz && tar -C / -xf graphite.tar && rm graphite.tar &&\
	wget -qO libbsd.tar.xz https://www.archlinux.org/packages/extra/x86_64/libbsd/download/ && unxz libbsd.tar.xz && tar -C / -xf libbsd.tar && rm libbsd.tar &&\
	wget -qO libpng.tar.xz https://www.archlinux.org/packages/extra/x86_64/libpng/download/ && unxz libpng.tar.xz && tar -C / -xf libpng.tar && rm libpng.tar &&\
	wget -qO glib2.tar.xz https://www.archlinux.org/packages/core/x86_64/glib2/download/ && unxz glib2.tar.xz && tar -C / -xf glib2.tar && rm glib2.tar &&\
	downloadPage="$(wget -qO- https://wire.com/en/download/ | grep -o '/stat[^\"]*')" && \
	[ "${downloadPage: -4}" == "json" ] && [ "${downloadPage:5:1}" == "i" ] || false && \
	filename=$(wget -qO- "https://wire.com/${downloadPage:0:100}" | grep -o '[^\/]*amd64.deb') &&\
	[ "${filename:0:4}" == "wire" ] || false && \
	wget -qO wire.deb "https://wire-app.wire.com/linux/debian/pool/main/${filename:0:30}" && \
	ar x wire.deb data.tar.xz || false && \
	[ "$(head -n 1 wire.deb)" == "!<arch>" ] || false && \
	tar -C / -xf data.tar.xz && \
	apk del binutils &&\
	rm \
		wire.deb data.tar.xz \
		/var/cache/apk/* \
		glibc.apk glibc-bin.apk \
		/etc/apk/keys/sgerrand.rsa.pub &&\
	sed -i 's/^\(guest:x\)\(:[0-9]*\)\{2\}/\1:'"${RUNAS}"'/g' /etc/passwd && \
	sed -i 's/^\(users:x:\)[0-9]*/\1'"${RUNAS#*:}"'/g' /etc/group && \
	sed -i 's/^\(audio:x:\)[0-9]*/\1'"${AUDIOGID#*:}"'/g' /etc/group && \
	adduser guest audio
USER guest
# NODE_EXTRA_CA_CERTS OPENSSL_CONF SOCKS_SERVER
ENV HOME=/appdata DISPLAY=:0 \
	ELECTRON_ENABLE_LOGGING=1 \
	NODE_DEBUG_NATIVE=1 DEBUG=1 \
	DEBUG_FD=2 ELECTRON_LOG_ASAR_READS=1 \
	NODE_DEBUG=1 \
	NODE_DEBUG=async \
	ELECTRON_ENABLE_STACK_DUMPING=1 \
	TMPDIR=/appdata/tmp/ \
	NODE_V8_COVERAGE=/appdata/cov/

CMD ["/opt/Wire/wire-desktop"]
