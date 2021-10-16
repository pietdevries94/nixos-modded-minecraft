{ pkgs ? import <nixpkgs> { } }:

{ mods, minecraftVersion, fabricLoaderVersion }:

with pkgs;
with lib;

let
  copyMods = type: modSet: concatStringsSep "\n" (attrsets.mapAttrsToList (name: mod: "cp ${mod.src} .minecraft/mods/${name}.jar") (attrsets.filterAttrs (name: mod: mod.${type}) modSet));

  mmcPackJsonFile = builtins.toFile "mmc-pack.json" ''{
    "components": [
        {
            "cachedName": "LWJGL 3",
            "cachedVersion": "3.2.2",
            "cachedVolatile": true,
            "dependencyOnly": true,
            "uid": "org.lwjgl3",
            "version": "3.2.2"
        },
        {
            "cachedName": "Minecraft",
            "cachedRequires": [
                {
                    "equals": "3.2.2",
                    "suggests": "3.2.2",
                    "uid": "org.lwjgl3"
                }
            ],
            "cachedVersion": "${minecraftVersion}",
            "important": true,
            "uid": "net.minecraft",
            "version": "${minecraftVersion}"
        },
        {
            "cachedName": "Intermediary Mappings",
            "cachedRequires": [
                {
                    "equals": "${minecraftVersion}",
                    "uid": "net.minecraft"
                }
            ],
            "cachedVersion": "${minecraftVersion}",
            "cachedVolatile": true,
            "dependencyOnly": true,
            "uid": "net.fabricmc.intermediary",
            "version": "${minecraftVersion}"
        },
        {
            "cachedName": "Fabric Loader",
            "cachedRequires": [
                {
                    "uid": "net.fabricmc.intermediary"
                }
            ],
            "cachedVersion": "${fabricLoaderVersion}",
            "uid": "net.fabricmc.fabric-loader",
            "version": "${fabricLoaderVersion}"
        }
    ],
    "formatVersion": 1
}'';
  instanceCfgFile = builtins.toFile "instance.cfg" 
  ''InstanceType=OneSix
JoinServerOnLaunch=false
OverrideCommands=false
OverrideConsole=false
OverrideGameTime=false
OverrideJavaArgs=false
OverrideJavaLocation=false
OverrideMemory=false
OverrideNativeWorkarounds=false
OverrideWindow=false
iconKey=default
name=Modpack
notes=
'';

in
stdenv.mkDerivation {
  name = "minecraft-fabric-server-mods";

  preferLocalBuild = true;

  buildPhase = ''
    mkdir -p .minecraft/mods
    ${copyMods "client" mods}
    cp ${mmcPackJsonFile} mmc-pack.json
    cp ${instanceCfgFile} instance.cfg

    ${pkgs.zip}/bin/zip -r modpack.zip \
      .minecraft \
      mmc-pack.json \
      instance.cfg
  '';

  installPhase = ''
    mkdir -p $out
    cp modpack.zip $out/modpack.zip
  '';

  phases = "buildPhase installPhase";
}