{
  name = "";

  type = "vanilla"; # vanilla | cf | mr | ftb | gtnh
  slug = ""; # required for cf/mr, optional for others
  zip = false; # mount ./pack/modpack.zip

  cfMods = ""; # newline-separated extra mod slugs
  cfExclude = ""; # newline-separated slugs, becomes comma list

  mrProjects = ""; # newline-separated, same idea as cfMods

  extraEnv = { };

  docker = {
    java = 21; # itzg/minecraft-server:java<N>
    memory = "6G";
    aikar = true;
    jvmOpts = "";
    clearMods = true; # REMOVE_OLD_MODS
    restart = "unless-stopped";
    port = 25565;
  };

  server = {
    version = "LATEST";
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
    maxTickTime = -1;
    seed = "";
    whitelist = [ ];
    ops = [ ];
  };
}
