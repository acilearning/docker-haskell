ARG DEBIAN_VERSION=11.4
FROM "debian:$DEBIAN_VERSION-slim"

# Install dependencies.

ENV LANG=C.UTF-8
RUN \
  set -o errexit -o xtrace; \
  apt-get update; \
  env DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes --no-install-recommends \
    ca-certificates \
    curl \
    clang \
    libgmp-dev \
    libnuma-dev \
    llvm-dev \
    make \
    sudo \
    zlib1g-dev; \
  rm --recursive /var/lib/apt/lists/*

# Create user.

ARG USER_NAME=haskell
RUN \
  set -o errexit -o xtrace; \
  useradd --create-home --groups sudo --shell "$( command -v bash )" "$USER_NAME"; \
  echo "$USER_NAME ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$USER_NAME"

# Configure user.

USER "$USER_NAME"
WORKDIR "/home/$USER_NAME"
RUN mkdir --parents ~/.cabal/bin ~/.ghcup/bin
ENV PATH="/home/$USER_NAME/.cabal/bin:/home/$USER_NAME/.ghcup/bin:$PATH"

# Install GHCup.

ARG GHCUP_VERSION=0.1.17.8
RUN \
  set -o errexit -o xtrace; \
  curl --output ~/.ghcup/bin/ghcup "https://downloads.haskell.org/~ghcup/$GHCUP_VERSION/$( uname --machine )-linux-ghcup-$GHCUP_VERSION"; \
  chmod +x ~/.ghcup/bin/ghcup; \
  ghcup --version

# Install GHC.

ARG GHC_VERSION=9.0.2
RUN \
  set -o errexit -o xtrace; \
  ghcup install ghc "$GHC_VERSION" --set; \
  ghc --version

# Install Cabal.

ARG CABAL_VERSION=3.6.2.0
RUN \
  set -o errexit -o xtrace; \
  ghcup install cabal "$CABAL_VERSION" --set; \
  cabal --version

# Install HLS.

ARG HLS_VERSION=1.7.0.0
RUN \
  set -o errexit -o xtrace; \
  ghcup install hls "$HLS_VERSION" --set; \
  haskell-language-server-wrapper --version

# Configure Cabal.

ARG CABAL_STORE=/cabal-store
RUN \
  set -o errexit -o xtrace; \
  sudo mkdir --mode 0775 --parents "$CABAL_STORE"; \
  sudo chown "$USER_NAME" "$CABAL_STORE"; \
  sudo chgrp sudo "$CABAL_STORE"; \
  cabal user-config init --augment "store-dir: $CABAL_STORE"
VOLUME "/cabal-store"
VOLUME "/home/$USER_NAME/.cabal"
