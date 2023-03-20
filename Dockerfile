ARG DEBIAN_VERSION=11
FROM "mcr.microsoft.com/devcontainers/base:debian-$DEBIAN_VERSION"

# Install dependencies.

ENV LANG=C.UTF-8
RUN \
  set -o errexit -o xtrace; \
  apt-get update; \
  env DEBIAN_FRONTEND=noninteractive apt-get install --assume-yes --no-install-recommends \
    inotify-tools \
    libgmp-dev \
    liblzma-dev \
    libnuma-dev \
    libpq-dev; \
  rm --recursive --verbose /var/lib/apt/lists/*

# Configure user.

ARG USER_NAME=vscode
USER "$USER_NAME"
WORKDIR "/home/$USER_NAME"
RUN mkdir --parents --verbose \
  ~/.cache/cabal \
  ~/.local/bin \
  ~/.local/share/stack \
  ~/.local/state/cabal
ENV PATH="/home/$USER_NAME/.local/bin:$PATH"

# Install GHCup.

ARG GHCUP_VERSION=0.1.19.2
ENV GHCUP_USE_XDG_DIRS=1
RUN \
  set -o errexit -o xtrace; \
  if test -n "$GHCUP_VERSION"; then \
    curl --output ~/.local/bin/ghcup "https://downloads.haskell.org/ghcup/$GHCUP_VERSION/$( uname --machine )-linux-ghcup-$GHCUP_VERSION"; \
    chmod --verbose +x ~/.local/bin/ghcup; \
    ghcup --version; \
  fi

# Install GHC.

ARG GHC_VERSION=9.4.4
RUN \
  set -o errexit -o xtrace; \
  if test -n "$GHC_VERSION"; then \
    ghcup install ghc "$GHC_VERSION" --set; \
    ghcup gc --profiling-libs --share-dir; \
    ghc --version; \
  fi

# Install Cabal.

ARG CABAL_VERSION=3.10.1.0
RUN \
  set -o errexit -o xtrace; \
  if test -n "$CABAL_VERSION"; then \
    ghcup install cabal "$CABAL_VERSION" --set; \
    cabal --version; \
    cabal user-config init; \
  fi

# Install Stack.

ARG STACK_VERSION=2.9.3
ENV STACK_XDG=1
RUN \
  set -o errexit -o xtrace; \
  if test -n "$STACK_VERSION"; then \
    ghcup install stack "$STACK_VERSION" --set; \
    stack --version; \
    stack config set install-ghc --global false; \
    stack config set system-ghc --global true; \
  fi

# Install HLS.

ARG HLS_VERSION=1.9.1.0
RUN \
  set -o errexit -o xtrace; \
  if test -n "$HLS_VERSION"; then \
    if echo "$HLS_VERSION" | grep --extended-regexp --quiet '^[0-9a-f]{40}$'; then \
      ghcup --verbose compile hls --cabal-update --ghc "$GHC_VERSION" --git-describe-version --git-ref "$HLS_VERSION" -- --flags=-dynamic --ghc-options='+RTS -M2G -RTS' --index-state='2022-11-11T21:44:45Z'; \
    else \
      ghcup install hls "$HLS_VERSION" --set; \
    fi; \
    ghcup gc --hls-no-ghc --tmpdirs; \
    rm --force --recursive --verbose "$CABAL_STORE/*" ~/.cabal/{logs,packages,store}; \
    haskell-language-server-wrapper --version; \
  fi
