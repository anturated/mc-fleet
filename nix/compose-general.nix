{
  cfg,
  lib,
  bool,
}:

let
  d = cfg.docker;
  s = cfg.server;

  # sanity checks

  env = {
    EULA = "TRUE";
  }
  # docker
  // {
    MEMORY = d.memory;
    VERSION = d.version;
    USE_AIKAR_FLAGS = bool d.aikar;
    REMOVE_OLD_MODS = bool d.clearMods;
  }
  # server
  // {
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
in
env
