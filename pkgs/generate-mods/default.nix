{ pkgs ? import <nixpkgs> { } }:

with pkgs;

let
  script = ./generate-mods.ts;
  wrapper = writeScript "generate-mods" ''#!${bash}/bin/bash
${deno}/bin/deno run -A ${script} "$@"
  '';
in
stdenv.mkDerivation {
  pname = "minecraft-mod-generator";
  version = "0.1.0";

  propagatedBuildInputs = [ nix-prefetch ];

  preferLocalBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cp ${wrapper} $out/bin/generate-mods
  '';

  phases = "installPhase";

  meta = with lib; {
    description = "Minecraft Mod Generator";
    platforms = platforms.unix;
  };
}