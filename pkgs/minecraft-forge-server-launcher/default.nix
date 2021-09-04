{ pkgs ? import <nixpkgs> { } }:

with pkgs;

stdenv.mkDerivation {
  pname = "minecraft-forge-server-launcher";
  version = "0.1.0";

  preferLocalBuild = true;

  installPhase = ''
    mkdir -p $out/bin
    cat > $out/bin/minecraft-forge-server-launcher << EOF
    #!/bin/sh

    # Exit when a command fails
    set -e

    # Check if config exists
    if [ ! -f "minecraft-forge-server-launcher.conf" ]; then
      echo "Config is needed. minecraft-forge-server-launcher.conf is created. Please fill this file"
      
      echo "# Get the version from https://files.minecraftforge.net" > minecraft-forge-server-launcher.conf
      echo "forgeVersion=" >> minecraft-forge-server-launcher.conf
      echo "jvmOpts=" >> minecraft-forge-server-launcher.conf
      exit 1
    fi

    # load config
    export \$(grep -v '^#' minecraft-forge-server-launcher.conf | xargs -d '\n')

    # Check if version is given
    if [[ \$forgeVersion = "" ]]; then
      echo "forgeVersion in config is required"
      exit 1
    fi

    # Ensure correct forge is installed
    if [ ! -d "libraries/net/minecraftforge/forge/\$forgeVersion" ]; then
      # cleanup to prevent a growing library folder
      rm -rf libraries

      curl https://maven.minecraftforge.net/net/minecraftforge/forge/\$forgeVersion/forge-\$forgeVersion-installer.jar -o installer.jar
      ${jre_headless}/bin/java -jar installer.jar --installServer

      # Cleanup if succesful
      rm -f installer.jar
      rm -f installer.jar.log
      rm -f run.bat
      rm -f run.sh
      rm -f user_jvm_args.txt
    fi

    ${jre_headless}/bin/java \$jvmOpts @libraries/net/minecraftforge/forge/\$forgeVersion/unix_args.txt nogui
    EOF
    chmod +x $out/bin/minecraft-forge-server-launcher
  '';

  phases = "installPhase";

  meta = with lib; {
    description = "Minecraft Forge Server Launcher";
    license = licenses.unfreeRedistributable;
    platforms = platforms.unix;
  };
}