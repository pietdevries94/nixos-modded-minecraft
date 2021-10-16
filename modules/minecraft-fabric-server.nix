{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.minecraft-fabric-server;

  launcherPkg = import ../pkgs/minecraft-fabric-server-launcher { inherit pkgs; };

  # We don't allow eula=false anyways
  eulaFile = builtins.toFile "eula.txt" ''
    # eula.txt managed by NixOS Configuration
    eula=true
  '';

  whitelistFile = pkgs.writeText "whitelist.json"
    (builtins.toJSON
      (mapAttrsToList (n: v: { name = n; uuid = v; }) cfg.whitelist));

  cfgToString = v: if builtins.isBool v then boolToString v else toString v;

  serverPropertiesFile = pkgs.writeText "server.properties" (''
    # server.properties managed by NixOS configuration
  '' + concatStringsSep "\n" (mapAttrsToList
    (n: v: "${n}=${cfgToString v}") cfg.serverProperties));

  launcherConfigFile = pkgs.writeText "minecraft-fabric-server-launcher.conf" ''
    # minecraft-fabric-server-launcher.conf
    installerVersion=${cfg.fabricInstallerVersion}
    loaderVersion=${cfg.fabricLoaderVersion}
    minecraftVersion=${cfg.minecraftVersion}
    jvmOpts="${cfg.jvmOpts}"
  '';


  # To be able to open the firewall, we need to read out port values in the
  # server properties, but fall back to the defaults when those don't exist.
  # These defaults are from https://minecraft.gamepedia.com/Server.properties#Java_Edition_3
  defaultServerPort = 25565;

  serverPort = cfg.serverProperties.server-port or defaultServerPort;

  rconPort = if cfg.serverProperties.enable-rcon or false
    then cfg.serverProperties."rcon.port" or 25575
    else null;

  queryPort = if cfg.serverProperties.enable-query or false
    then cfg.serverProperties."query.port" or 25565
    else null;

  linkMods = type: modSet: concatStringsSep "\n" (attrsets.mapAttrsToList (name: mod: "ln -s ${mod.src} mods/${name}.jar") (attrsets.filterAttrs (name: mod: mod.${type}) modSet));
in {
  options = {
    services.minecraft-fabric-server = {

      enable = mkOption {
        type = types.bool;
        default = false;
        description = ''
          If enabled, start a Minecraft Server modde with fabric.
          The server data will be loaded from and saved to
          <option>services.minecraft-fabric-server.dataDir</option>.
        '';
      };

      declarative = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to use a declarative Minecraft server configuration.
          Only if set to <literal>true</literal>, the options
          <option>services.minecraft-fabric-server.whitelist</option> and
          <option>services.minecraft-fabric-server.serverProperties</option> will be
          applied.
        '';
      };

      eula = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether you agree to
          <link xlink:href="https://account.mojang.com/documents/minecraft_eula">
          Mojangs EULA</link>. This option must be set to
          <literal>true</literal> to run Minecraft server.
        '';
      };

      dataDir = mkOption {
        type = types.path;
        default = "/var/lib/minecraft-fabric-server";
        description = ''
          Directory to store Minecraft database and other state/data files.
        '';
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to open ports in the firewall for the server.
        '';
      };

      whitelist = mkOption {
        type = let
          minecraftUUID = types.strMatching
            "[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}" // {
              description = "Minecraft UUID";
            };
          in types.attrsOf minecraftUUID;
        default = {};
        description = ''
          Whitelisted players, only has an effect when
          <option>services.minecraft-fabric-server.declarative</option> is
          <literal>true</literal> and the whitelist is enabled
          via <option>services.minecraft-fabric-server.serverProperties</option> by
          setting <literal>white-list</literal> to <literal>true</literal>.
          This is a mapping from Minecraft usernames to UUIDs.
          You can use <link xlink:href="https://mcuuid.net/"/> to get a
          Minecraft UUID for a username.
        '';
        example = literalExpression ''
          {
            username1 = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx";
            username2 = "yyyyyyyy-yyyy-yyyy-yyyy-yyyyyyyyyyyy";
          };
        '';
      };

      serverProperties = mkOption {
        type = with types; attrsOf (oneOf [ bool int str ]);
        default = {};
        example = literalExpression ''
          {
            server-port = 43000;
            difficulty = 3;
            gamemode = 1;
            max-players = 5;
            motd = "NixOS Minecraft server!";
            white-list = true;
            enable-rcon = true;
            "rcon.password" = "hunter2";
          }
        '';
        description = ''
          Minecraft server properties for the server.properties file. Only has
          an effect when <option>services.minecraft-fabric-server.declarative</option>
          is set to <literal>true</literal>. See
          <link xlink:href="https://minecraft.gamepedia.com/Server.properties#Java_Edition_3"/>
          for documentation on these values.
        '';
      };

      package = mkOption {
        type = types.package;
        default = launcherPkg;
        description = "Version of minecraft-fabric-server-launcher to run.";
      };

      jvmOpts = mkOption {
        type = types.separatedString " ";
        default = "-Xmx2048M -Xms2048M";
        # Example options from https://minecraft.gamepedia.com/Tutorials/Server_startup_script
        example = "-Xmx2048M -Xms4092M -XX:+UseG1GC -XX:+CMSIncrementalPacing "
          + "-XX:+CMSClassUnloadingEnabled -XX:ParallelGCThreads=2 "
          + "-XX:MinHeapFreeRatio=5 -XX:MaxHeapFreeRatio=10";
        description = "JVM options for the Minecraft server.";
      };

      fabricInstallerVersion = mkOption {
        type = types.strMatching
          "[0-9]+\.[0-9]+\.[0-9]+" // {
            description = "Fabric installer version";
          };
        description = ''
          The version of the Fabric installer. Get the version here:
          <link xlink:href="https://fabricmc.net/use/"/>
        '';
        example = literalExpression "0.8.0";
      };

      fabricLoaderVersion = mkOption {
        type = types.strMatching
          "[0-9]+\.[0-9]+\.[0-9]+" // {
            description = "Fabric Loader version";
          };
        description = ''
          The version of the Fabric loader. Get the version here:
          <link xlink:href="https://maven.fabricmc.net/net/fabricmc/fabric-loader/"/>
        '';
        example = literalExpression "0.11.7";
      };

      minecraftVersion = mkOption {
        type = types.strMatching
          "[0-9]+\.[0-9]+(\.[1-9]+)?" // {
            description = "Minecraft version";
          };
        description = ''
          The version of Minecraft. Get the version here:
          <link xlink:href="https://minecraft.fandom.com/wiki/Java_Edition_version_history/"/>
        '';
        example = literalExpression "0.17.1";
      };

      mods = mkOption {
        type = with types; attrsOf (submodule {
          options = {
            client = mkOption {
              type = bool;
              default = false;
            };
            server = mkOption {
              type = bool;
              default = false;
            };
            src = mkOption {
              type = path;
            };
          };
        });
        default = {};
        example = literalExpression ''
          {
            fabric-api = {
              client = true;
              server = true;
              src = pkgs.fetchurl {
                name = "fabric-api-0.40.8-1.17.jar";
                url = https://media.forgecdn.net/files/3486/63/fabric-api-0.40.8%2B1.17.jar;
                sha256 = "0c6zxi5p6k4shwn0ly87rhsz9vsm98c5g7pg31rc04vfwyvispj0";
              };
            };
          }
        '';
        description = ''
          // TODO description for mods and add helpers for generating the fetches
        '';
      };
    };
  };

  config = mkIf cfg.enable {

    users.users.minecraft = {
      description     = "Minecraft server service user";
      home            = cfg.dataDir;
      createHome      = true;
      isSystemUser    = true;
      group           = "minecraft";
    };
    users.groups.minecraft = {};

    systemd.services.minecraft-fabric-server = {
      description   = "Minecraft Server Service";
      wantedBy      = [ "multi-user.target" ];
      after         = [ "network.target" ];

      serviceConfig = {
        ExecStart = "${cfg.package}/bin/minecraft-fabric-server-launcher";
        Restart = "always";
        User = "minecraft";
        WorkingDirectory = cfg.dataDir;
      };

      preStart = ''
        ln -sf ${eulaFile} eula.txt
      '' + (if cfg.declarative then ''
        rm -rf mods
        mkdir -p mods
        ${linkMods "server" cfg.mods}

        if [ -e .declarative ]; then

          # Was declarative before, no need to back up anything
          ln -sf ${launcherConfigFile} minecraft-fabric-server-launcher.conf
          ln -sf ${whitelistFile} whitelist.json
          cp -f ${serverPropertiesFile} server.properties

        else

          # Declarative for the first time, backup stateful files
          ln -sb --suffix=.stateful ${whitelistFile} whitelist.json
          cp -b --suffix=.stateful ${serverPropertiesFile} server.properties

          # server.properties must have write permissions, because every time
          # the server starts it first parses the file and then regenerates it..
          chmod +w server.properties
          echo "Autogenerated file that signifies that this server configuration is managed declaratively by NixOS" \
            > .declarative

        fi
      '' else ''
        if [ -e .declarative ]; then
          rm .declarative
        fi
      '');
    };

    networking.firewall = mkIf cfg.openFirewall (if cfg.declarative then {
      allowedUDPPorts = [ serverPort ];
      allowedTCPPorts = [ serverPort ]
        ++ optional (queryPort != null) queryPort
        ++ optional (rconPort != null) rconPort;
    } else {
      allowedUDPPorts = [ defaultServerPort ];
      allowedTCPPorts = [ defaultServerPort ];
    });

    assertions = [
      { assertion = cfg.eula;
        message = "You must agree to Mojangs EULA to run minecraft-fabric-server-launcher."
          + " Read https://account.mojang.com/documents/minecraft_eula and"
          + " set `services.minecraft-fabric-server.eula` to `true` if you agree.";
      }
      { assertion = cfg.fabricInstallerVersion != ""; }
      { assertion = cfg.fabricLoaderVersion != ""; }
      { assertion = cfg.minecraftVersion != ""; }
    ];

  };
}
