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
      
      echo "# Get the version from https://files.minecraftfabric.net" > minecraft-fabric-server-launcher.conf
      echo "fabricVersion=" >> minecraft-fabric-server-launcher.conf
      echo "jvmOpts=" >> minecraft-fabric-server-launcher.conf
      exit 1
    fi

    # load config
    export \$(grep -v '^#' minecraft-fabric-server-launcher.conf | xargs -d '\n')

    # Check if version is given
    if [[ \$fabricVersion = "" ]]; then
      echo "fabricVersion in config is required"
      exit 1
    fi

    # Ensure correct fabric is installed
    if [ ! -f "fabric-installer-\$fabricVersion.jar" ]; then
      # cleanup to prevent a growing library folder
      rm -rf libraries

      curl https://maven.fabricmc.net/net/fabricmc/fabric-installer/\$fabricVersion/fabric-installer-\$fabricVersion.jar -o fabric-installer-\$fabricVersion.jar
      ${jre_headless}/bin/java -jar fabric-installer-\$fabricVersion.jar server -downloadMinecraft
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