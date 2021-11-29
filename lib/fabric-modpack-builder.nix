{ pkgs ? import <nixpkgs> { } }:

{ mods, minecraftVersion, fabricLoaderVersion, hostModpack }:

with pkgs;
with lib;

let
  modpackUrl = "http://${hostModpack.hostname}${hostModpack.location}";

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

fancymenuDefault = builtins.toFile "Default.txt"
  ''type = menu

customization-meta {
  identifier = net.minecraft.class_442
  randomgroup = 1
  renderorder = foreground
  randommode = false
  randomonlyfirsttime = false
}

customization {
  keepaspectratio = false
  action = backgroundoptions
}

customization {
  orientation = bottom-left
  shadow = false
  multiline = false
  x = 3
  actionid = 358a5259-0c73-465a-a644-d4a3be6d8fa21638114860984
  action = addwebtext
  y = -33
  scale = 3.0
  alignment = left
  url = ${modpackUrl}/version-REPLACEMEWITHMCHASH.txt
}

customization {
  orientation = bottom-left
  loopbackgroundanimations = true
  restartbackgroundanimations = true
  buttonaction = openlink
  x = 2
  width = 100
  actionid = 094263b6-4f36-466c-b4f1-2bd402fbd6f01638187338407
  action = addbutton
  y = -57
  label = To Mod Website
  value = ${modpackUrl}
  height = 20
}
'';

fancymenucustomizablemenus = builtins.toFile "customizablemenus.txt"
  ''type = customizablemenus

net.minecraft.class_442 {
}

'';

  sameVersionFile = builtins.toFile "version-correct.txt" "Up to date! :D";
  outdatedVersionFile = builtins.toFile "version-outdated.txt" "WRONG VERSION PLEASE UPDATE!!!";

in
stdenv.mkDerivation {
  name = "minecraft-fabric-server-mods";

  preferLocalBuild = true;

  buildPhase = ''
    mkdir -p .minecraft/mods
    ${copyMods "client" mods}
    cp ${mmcPackJsonFile} mmc-pack.json
    cp ${instanceCfgFile} instance.cfg

    MCHASH=$(${pkgs.rhash}/bin/rhash -H -r . | ${pkgs.rhash}/bin/rhash -H -p '%h' -)
    echo $MCHASH > MCHASH.txt

    mkdir -p .minecraft/config/fancymenu/customization/
    cp ${fancymenuDefault} .minecraft/config/fancymenu/customization/Default.txt
    sed -i -e "s/REPLACEMEWITHMCHASH/$MCHASH/" .minecraft/config/fancymenu/customization/Default.txt
    cp ${fancymenucustomizablemenus} .minecraft/config/fancymenu/customizablemenus.txt

    ${pkgs.zip}/bin/zip -r modpack.zip \
      .minecraft \
      mmc-pack.json \
      instance.cfg
  '';

  installPhase = ''
    mkdir -p $out
    cp modpack.zip $out/modpack.zip
    MCHASH=$(cat MCHASH.txt)
    cp ${sameVersionFile} "$out/version-$MCHASH.txt"
    cp ${outdatedVersionFile} $out/version-outdated.txt
  '';

  phases = "buildPhase installPhase";
}