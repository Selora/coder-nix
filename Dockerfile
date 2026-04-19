FROM debian:13

ARG USERNAME=coder
ARG USER_UID=1000
ARG USER_GID=1000

SHELL ["/bin/bash", "-lc"]

RUN apt-get update && apt-get install -y --no-install-recommends \
	bash ca-certificates curl git sudo rsync xz-utils \
	openssh-client iproute2 bind9-dnsutils iputils-ping \
	less locales procps file tzdata unzip bash-completion \
	netcat-openbsd lsof strace vim \
	&& rm -rf /var/lib/apt/lists/*

RUN sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
	&& locale-gen \
	&& update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
	&& useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}" \
	&& mkdir -p /nix \
	&& chown "${USER_UID}:${USER_GID}" /nix \
	&& echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
	&& chmod 0440 /etc/sudoers.d/${USERNAME}

# System-level nix config survives even if $HOME is mounted fresh
RUN mkdir -p /etc/nix && cat >/etc/nix/nix.conf <<'EOF'
experimental-features = nix-command flakes
use-xdg-base-directories = true
EOF

USER ${USERNAME}
WORKDIR /home/${USERNAME}

ENV HOME=/home/${USERNAME}
ENV USER=${USERNAME}
ENV PATH=/home/${USERNAME}/.local/state/nix/profile/bin:/home/${USERNAME}/.nix-profile/bin:/nix/var/nix/profiles/default/bin:${PATH}

RUN sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon

# Fallback seed copy for backends that do not auto-populate the home volume
USER root
RUN mkdir -p /opt/coder-home-seed \
	&& rsync -a /home/${USERNAME}/ /opt/coder-home-seed/ \
	&& chown -R ${USER_UID}:${USER_GID} /opt/coder-home-seed
COPY --chmod=755 entrypoint.sh /usr/local/bin/entrypoint.sh

USER ${USERNAME}
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["/bin/bash"]
