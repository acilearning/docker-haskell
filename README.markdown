# docker-haskell

This Docker image provides a Haskell development environment with the following tools:

- [GHCup](https://www.haskell.org/ghcup/) version 0.1.20.0
- [GHC](https://www.haskell.org/ghc/) version 9.8.1, 9.6.3, or 9.4.7
- [Cabal](https://www.haskell.org/cabal/) version 3.10.2.0
- [Stack](https://docs.haskellstack.org/en/stable/) version 2.13.1
- [HLS](https://haskell-language-server.readthedocs.io/en/latest/) version 2.4.0.0

## Usage

This Docker image supports both AMD64 (`x86_64`) and ARM64 (`aarch64`) architectures.

To get started, select one of the supported versions of GHC.
The Docker image is available at `public.ecr.aws/acilearning/haskell:$GHC`.
For example, to use GHC 9.8.1 you would use the image `public.ecr.aws/acilearning/haskell:9.8.1`.

Note that the image tag can and often is updated with newer tools.
To pin a specific version, add the commit hash to the end of the tag.
The format is `public.ecr.aws/acilearning/haskell:$GHC-$COMMIT`.
For example, to use GHC 9.8.1 at a specific commit you would use the image `public.ecr.aws/acilearning/haskell:9.8.1-3a8c34f81332de06c4c2239e144a63dfd11de9f0`.
This is recommended for reproducible builds.

## Development Container

This Docker image is designed to be used as a [Development Container](https://containers.dev/).

Here is an example `.devcontainer.json` file:

``` json
{
  "customizations": { "vscode": { "extensions": [ "haskell.haskell" ] } },
  "dockerComposeFile": "compose.yaml",
  "postCreateCommand": "cabal update",
  "postStartCommand": "git config --global --add safe.directory \"$PWD\"",
  "service": "devcontainer",
  "workspaceFolder": "/workspace"
}
```

And the corresponding `compose.yaml` file:

``` yaml
services:
  devcontainer:
    command: sleep infinity
    image: public.ecr.aws/acilearning/haskell:9.8.1-3a8c34f81332de06c4c2239e144a63dfd11de9f0
    init: true
    volumes: [ .:/workspace ]
    working_dir: /workspace
```

Depending on your specific scenario, you may want to create volumes one or more of the following directories:

- Cabal's cache: `/home/vscode/.cache/cabal`
- Cabal's state: `/home/vscode/.local/state/cabal` (can be an external volume shared between projects)
- Stack's share: `/home/vscode/.local/share/stack`
