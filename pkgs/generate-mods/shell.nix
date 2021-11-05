{ pkgs ? import <nixpkgs> {} }:

let
  url = https://github.com/nixos/nixpkgs/archive/nixpkgs-unstable.tar.gz;
  unstable = import (fetchTarball url) {};
in
pkgs.mkShell {
  buildInputs = [
    unstable.deno
    pkgs.nix-prefetch
  ];
}
