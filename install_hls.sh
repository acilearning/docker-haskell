#!/usr/bin/env bash

set -o errexit -o xtrace; \
  if [[ "$GHC_VERSION" == "9.2.4" ]]; then \
    if test -n "$HLS_VERSION"; then \
    ghcup compile hls -j4 -g 26a6ca607930b85bb1a2491b8deaf1a363c2e3df --ghc $GHC_VERSION --cabal-update; \
    else \
      ghcup install hls "$HLS_VERSION" --set; \
    fi
  ghcup gc --hls-no-ghc; \
  haskell-language-server-wrapper --version; \
  fi
