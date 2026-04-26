{ pkgs }:

let
  lib = pkgs.lib;
  defaults = import ./defaults.nix;
  yaml = pkgs.formats.yaml { };
  bool = b: if b then "TRUE" else "FALSE";

  typeMap = {
    vanilla = "VANILLA";
    cf = "AUTO_CURSEFORGE";
    mr = "MODRINTH";
    ftb = "FTBA";
    gtnh = "CUSTOM"; # itzg CUSTOM + CUSTOM_SERVER; slug unused
  };
in
name: userCfg:
let
  cfg = lib.recursiveUpdate defaults userCfg;
  d = cfg.docker;
  s = cfg.server;

  # assertions
  _ = if cfg.name == "" then throw "servers/${name}/config.nix: name is required" else null;
  __ =
    if (cfg.type == "cf" || cfg.type == "mr") && cfg.slug == "" && !cfg.zip then # TODO: check ftb & GTNH
      throw "servers/${name}/config.nix: slug required for type '${cfg.type}' without zip"
    else
      null;

  itzgType = typeMap.${cfg.type} or (throw "unknown type '${cfg.type}'");

  # ── Base env ────────────────────────────────────────────
  baseEnv = {
    EULA = "TRUE";
    TYPE = itzgType;
    VERSION = s.version;
    MEMORY = d.memory;
    USE_AIKAR_FLAGS = bool d.aikar;
    REMOVE_OLD_MODS = bool d.clearMods;
    MAX_TICK_TIME = toString s.maxTickTime;
    MOTD = s.motd;
    DIFFICULTY = s.difficulty;
    MAX_PLAYERS = toString s.players;
    VIEW_DISTANCE = toString s.distance;
    SIMULATION_DISTANCE = toString s.simDistance;
    ALLOW_FLIGHT = bool s.flight;
    PVP = bool s.pvp;
    ENABLE_COMMAND_BLOCK = bool s.commandBlocks;
    ONLINE_MODE = bool s.onlineMode;
    SPAWN_PROTECTION = toString s.spawnProtection;
  }
  // lib.optionalAttrs (d.jvmOpts != "") { JVM_OPTS = d.jvmOpts; }
  // lib.optionalAttrs (s.seed != "") { LEVEL_SEED = s.seed; }
  // lib.optionalAttrs (s.ops != [ ]) { OPS = lib.concatStringsSep "," s.ops; }
  // lib.optionalAttrs (s.whitelist != [ ]) {
    WHITELIST = lib.concatStringsSep "," s.whitelist;
    ENABLE_WHITELIST = "TRUE";
  };

  hostingEnv =
    if cfg.type == "cf" then
      lib.optionalAttrs (cfg.slug != "") { CF_SLUG = cfg.slug; }
      // lib.optionalAttrs cfg.zip { CF_MODPACK_ZIP = "/pack/modpack.zip"; }
      // lib.optionalAttrs (cfg.cfMods != "") { CURSEFORGE_FILES = cfg.cfMods; }
      // lib.optionalAttrs (cfg.cfExclude != "") {
        CF_EXCLUDE_MODS = lib.concatStringsSep "," (
          lib.filter (s: s != "") (lib.splitString "\n" cfg.cfExclude)
        );
      }

    else if cfg.type == "mr" then
      lib.optionalAttrs (cfg.slug != "") { MODRINTH_PROJECT = cfg.slug; }
      // lib.optionalAttrs cfg.zip { MODRINTH_MODPACK_URL = "/pack/modpack.zip"; }
      // lib.optionalAttrs (cfg.mrProjects != "") { MODRINTH_PROJECTS = cfg.mrProjects; }

    else if cfg.type == "ftb" then
      lib.optionalAttrs (cfg.slug != "") { FTB_MODPACK_ID = cfg.slug; }

    else
      { }; # TODO: vanilla & GTNH

  volumes = [ "./data:/data" ] ++ lib.optionals cfg.zip [ "./pack:/pack" ];

  doc = {
    services.mc = {
      image = "itzg/minecraft-server:java${toString d.java}";
      container_name = "minecraft-${cfg.name}";
      stdin_open = true;
      tty = true;
      ports = [ "${toString d.port}:25565" ];
      env_file = [ ".env" ];
      environment = baseEnv // hostingEnv // cfg.extraEnv;
      inherit volumes;
      restart = d.restart;
    };
  };
in
yaml.generate "compose-${name}.yaml" doc
