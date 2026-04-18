FROM debian:13

LABEL org.opencontainers.image.source=https://github.com/Selora/coder-nix
LABEL org.opencontainers.image.description="Debian 13 base with Nix"

ARG USERNAME=coder
ARG USER_UID=1000
ARG USER_GID=1000
ARG WORKSPACES_DIR=/workspaces

SHELL ["/bin/bash", "-lc"]

RUN apt-get update && apt-get install -y --no-install-recommends \
  vim \
	bash \
	ca-certificates \
	curl \
	git \
	sudo \
  openssh-client \
  iproute2 \
  bind9-dnsutils \
  iputils-ping \
  less \
  locales \
  procps \
  file \
  tzdata \
  unzip \
  bash-completion \
  netcat-openbsd \
  rsync \
  lsof \
  strace \
	xz-utils \
	&& rm -rf /var/lib/apt/lists/*

RUN sed -i 's/^# *en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && locale-gen \
    && update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN groupadd --gid "${USER_GID}" "${USERNAME}" \
	&& useradd --uid "${USER_UID}" --gid "${USER_GID}" -m -s /bin/bash "${USERNAME}" \
	&& mkdir -p /nix \
	&& chown "${USER_UID}:${USER_GID}" /nix \
	&& echo "${USERNAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
	&& chmod 0440 /etc/sudoers.d/${USERNAME}

# Coder-specific persistent workspaces mount-point
RUN mkdir -p ${WORKSPACES_DIR} && chown "${USER_UID}":"${USER_GID}" ${WORKSPACES_DIR}

USER ${USERNAME}
WORKDIR /home/${USERNAME}

ENV HOME=/home/${USERNAME}
ENV USER=${USERNAME}
ENV PATH=${HOME}/.nix-profile/bin:${HOME}/.local/state/nix/profile/bin:/nix/var/nix/profiles/default/bin:${PATH}

RUN ln -s ${WORKSPACES_DIR} ${HOME}/workspaces

RUN sh <(curl --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon

RUN mkdir -p ${HOME}/.config/nix \
	&& printf 'experimental-features = nix-command flakes\n' > ${HOME}/.config/nix/nix.conf

ENV PATH="/home/${USERNAME}/.nix-profile/bin:/home/${USERNAME}/.local/state/nix/profile/bin:${PATH}"

RUN nix --version


CMD ["/bin/bash"]
