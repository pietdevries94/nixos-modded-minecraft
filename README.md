# nixos-modded-minecraft

A very wip nixos module with some tooling to setup modded minecraft servers and in the future, clients.

## Disclaimer

As a compromise to not completely have to hack into/rewrite the forge and fabric installers, there is a wrapper used which will download the correct version of forge/fabric in the data folder if needed and launch it. It's not the nix way, but it's a compromise I'm willing to make.
