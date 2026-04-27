{
  # Modpack platform
  # vanilla | cf | mr | ftb | gtnh
  type = "vanilla";

  # If the server folder contains a modpack.zip or modpack.mrpack ignore this
  #
  # Downloads modpack with given slug
  # FTB uses ID, paste this from link: <id>-modpack-name-<version>
  # or just the <id> part
  slug = "";

  # Newline separated list of extra mods (by slug)
  addMods = "";

  # Newline separated list of mods to ignore/remove (by slug)
  removeMods = "";

  # For the rare case where a mod is blocking download
  # and the API check doesn't suffice
  requiresZip = false;

  # These go into docker environment
  extraEnv = { };

  # Quick access to some stuff
  docker = {
    java = 21; # itzg/minecraft-server:java<N>
    memory = "6G";
    aikar = true;
    jvmOpts = "";
    clearMods = true; # REMOVE_OLD_MODS
    restart = "unless-stopped";
    port = 25565;
    version = "LATEST"; # minecraft version
  };

  # Quick access to server.properties
  server = {
    motd = "mc-fleet server";
    difficulty = "normal";
    players = 20;
    distance = 10;
    simDistance = 8;
    flight = true; # solves a lot of random kicks
    pvp = true;
    commandBlocks = false;
    onlineMode = true;
    spawnProtection = 16;
    maxTickTime = -1; # doesn't crash the server if it freezes for too long
    seed = "";
    whitelist = [ ];
    ops = [ ];
  };
}
