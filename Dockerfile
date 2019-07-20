FROM archlinux/base
RUN pacman -Sy --noconfirm gcc-libs base base-devel xdg-utils alsa-lib graphite libbsd glib2
RUN useradd -ms /bin/bash -g users -G audio system
ENV DISPLAY=:0 PULSE_SERVER=/run/pulseaudio
ARG PKGS
RUN pacman -Sy --noconfirm ${PKGS}
USER system
CMD ["bash"]
#CMD ["systemd-cat", "wire-desktop"]
#CMD ["${CMD}"]
