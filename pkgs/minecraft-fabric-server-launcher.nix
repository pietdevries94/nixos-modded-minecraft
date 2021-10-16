{ pkgs ? import <nixpkgs> { } }:

with pkgs;

stdenv.mkDerivation {
  pname = "minecraft-fabric-server-launcher";
  version = "0.1.0";


  preferLocalBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cat > $out/bin/minecraft-fabric-server-launcher << EOF
    #!/bin/sh

    # Exit when a command fails
    set -e

    # Check if config exists
    if [ ! -f "minecraft-fabric-server-launcher.conf" ]; then
      echo "Config is needed. minecraft-fabric-server-launcher.conf is created. Please fill this file"
      
      echo "# Get the installer version from https://fabricmc.net/use/" > minecraft-fabric-server-launcher.conf
      echo "installerVersion=" >> minecraft-fabric-server-launcher.conf
      echo "# Get the loader version from https://maven.fabricmc.net/net/fabricmc/fabric-loader/" >> minecraft-fabric-server-launcher.conf
      echo "loaderVersion=" >> minecraft-fabric-server-launcher.conf
      echo "# Get the Minecraft version from https://minecraft.fandom.com/wiki/Java_Edition_version_history/" >> minecraft-fabric-server-launcher.conf
      echo "minecraftVersion=" >> minecraft-fabric-server-launcher.conf
      echo "jvmOpts=\"\"" >> minecraft-fabric-server-launcher.conf
      exit 1
    fi

    # load config
    set -a
    source ./minecraft-fabric-server-launcher.conf
    set +a

    # Check if versions are given
    missingConf=0
    if [[ \$installerVersion = "" ]]; then
      echo "installerVersion in config is required"
      missingConf=1
    fi
    if [[ \$loaderVersion = "" ]]; then
      echo "loaderVersion in config is required"
      missingConf=1
    fi
    if [[ \$minecraftVersion = "" ]]; then
      echo "minecraftVersion in config is required"
      missingConf=1
    fi
    if [ \$missingConf -eq 1 ]; then
      exit 1
    fi

    # Ensure correct fabric is installed
    if
      [ ! -f "fabric-installer-\$installerVersion.jar" ] ||
      [ ! -f ".fabric-installer/libraries/net/fabricmc/fabric-loader/\$loaderVersion/fabric-loader-\$loaderVersion.jar" ] ||
      [ ! -f ".fabric/remappedJars/minecraft-\$minecraftVersion/intermediary-server.jar" ]
    then
      # cleanup to prevent a growing library folder
      rm -rf .fabric-installer
      rm -rf .fabric

      ${curl}/bin/curl https://maven.fabricmc.net/net/fabricmc/fabric-installer/\$installerVersion/fabric-installer-\$installerVersion.jar -o fabric-installer-\$installerVersion.jar
      ${jre_headless}/bin/java -jar fabric-installer-\$installerVersion.jar server -mcversion \$minecraftVersion -loader \$loaderVersion -downloadMinecraft
    fi

    ${jre_headless}/bin/java \$jvmOpts -jar fabric-server-launch.jar nogui
    EOF
    chmod +x $out/bin/minecraft-fabric-server-launcher
  '';

  phases = "installPhase";

  meta = with lib; {
    description = "Minecraft Fabric Server Launcher";
    license = licenses.unfreeRedistributable;
    platforms = platforms.unix;
  };
}