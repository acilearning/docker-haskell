ARG DEBIAN_VERSION=11.5
FROM "debian:$DEBIAN_VERSION-slim"

# Install dependencies.

ENV LANG=C.UTF-8
RUN \
  set -o errexit -o xtrace; \
  apt-get update; \
  env DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes --no-install-recommends \
    ca-certificates \
    clang \
    curl \
    git \
    inotify-tools \
    libgmp-dev \
    liblzma-dev \
    libnuma-dev \
    libpq-dev \
    llvm-dev \
    make \
    nano \
    netbase \
    ssh-client \
    sudo \
    zlib1g-dev; \
  rm --recursive --verbose /var/lib/apt/lists/*

# Create user.

ARG USER_NAME=haskell
RUN \
  set -o errexit -o xtrace; \
  useradd --create-home --groups sudo --shell "$( command -v bash )" "$USER_NAME"; \
  echo "$USER_NAME ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$USER_NAME"

# Configure user.

USER "$USER_NAME"
WORKDIR "/home/$USER_NAME"
RUN mkdir --parents --verbose ~/.cabal/bin ~/.cache ~/.ghcup/bin ~/.local/bin
ENV PATH="/home/$USER_NAME/.local/bin:/home/$USER_NAME/.cabal/bin:/home/$USER_NAME/.ghcup/bin:$PATH"

# Install GHCup.

ARG GHCUP_VERSION=0.1.18.0
RUN \
  set -o errexit -o xtrace; \
  if test -n "$GHCUP_VERSION"; then \
    curl --output ~/.ghcup/bin/ghcup "https://downloads.haskell.org/ghcup/$GHCUP_VERSION/$( uname --machine )-linux-ghcup-$GHCUP_VERSION"; \
    chmod --verbose +x ~/.ghcup/bin/ghcup; \
    ghcup --version; \
  fi

# Install GHC.

ARG GHC_VERSION=9.0.2
RUN \
  set -o errexit -o xtrace; \
  if test -n "$GHC_VERSION"; then \
    ghcup install ghc "$GHC_VERSION" --set; \
    ghcup gc --profiling-libs --share-dir; \
    ghc --version; \
  fi

# Install Cabal.

ARG CABAL_VERSION=3.8.1.0
RUN \
  set -o errexit -o xtrace; \
  if test -n "$CABAL_VERSION"; then \
    ghcup install cabal "$CABAL_VERSION" --set; \
    cabal --version; \
  fi

# Configure Cabal.

ARG CABAL_STORE=/cabal-store
RUN \
  set -o errexit -o xtrace; \
  if command -v cabal; then \
    sudo mkdir --mode 0775 --parents --verbose "$CABAL_STORE"; \
    sudo chown --verbose "$USER_NAME" "$CABAL_STORE"; \
    sudo chgrp --verbose sudo "$CABAL_STORE"; \
    cabal user-config init --augment "store-dir: $CABAL_STORE"; \
  fi

# Install Stack.

ARG STACK_VERSION=2.9.1
RUN \
  set -o errexit -o xtrace; \
  if test -n "$STACK_VERSION"; then \
    ghcup install stack "$STACK_VERSION" --set; \
    stack --version; \
  fi

# Configure Stack.

ARG STACK_ROOT=/stack-root
RUN \
  set -o errexit -o xtrace; \
  if command -v stack; then \
    sudo mkdir --mode 0775 --parents --verbose "$STACK_ROOT"; \
    sudo chown --verbose "$USER_NAME" "$STACK_ROOT"; \
    sudo chgrp --verbose sudo "$STACK_ROOT"; \
    stack config set install-ghc --global false; \
    stack config set system-ghc --global true; \
  fi
ENV STACK_ROOT="$STACK_ROOT"

# Install HLS.

ARG HLS_VERSION=1.8.0.0
RUN \
  set -o errexit -o xtrace; \
  if test -n "$HLS_VERSION"; then \
    if echo "$HLS_VERSION" | grep --extended-regexp --quiet '^[0-9a-f]{40}$'; then \
      ghcup --verbose compile hls --cabal-update --ghc "$GHC_VERSION" --git-describe-version --git-ref "$HLS_VERSION" -- --flags=-dynamic --ghc-options='+RTS -M2G -RTS' --index-state='2022-11-11T21:44:45Z'; \
    else \
      ghcup install hls "$HLS_VERSION" --set; \
    fi; \
    ghcup gc --cache --hls-no-ghc --tmpdirs; \
    rm --force --recursive --verbose "$CABAL_STORE/*" ~/.cabal/{logs,packages,store}; \
    haskell-language-server-wrapper --version; \
  fi

# Configure volumes.

VOLUME "/home/$USER_NAME/.cabal"
VOLUME "/home/$USER_NAME/.cache"
VOLUME "/home/$USER_NAME/.stack"
VOLUME "$CABAL_STORE"
VOLUME "$STACK_ROOT"
