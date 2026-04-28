{ pkgs, lib }: # Jesus
let
  yaml = pkgs.formats.yaml { };
  bool = b: if b then "TRUE" else "FALSE";
  javaForVersion =
    version:
    let
      v = builtins.compareVersions version;
    in
    if v "1.17" < 0 then
      8
    else if v "1.18" < 0 then
      16
    else if v "1.20.5" < 0 then
      17
    else if v "26.1" < 0 then
      21
    else
      25;
in
{ name, cfg }:
let
  # merge configs
  d = cfg.docker;

  # sanity checks
  hasProperType = builtins.elem cfg.type [
    "cf"
    "mr"
    "ftb"
    "gtnh"
    "vanilla"
  ];
  _ =
    if !hasProperType && cfg.type != "" then
      throw "type should be one of <vanilla | cf | mr | ftb | gtnh> or empty"
    else
      null;

  hasMcVersion = cfg.version != "";
  hasJavaVersion = d.java != 0;
  __ =
    if !hasJavaVersion && !hasMcVersion then
      throw "Set version=\"your.mc.version\" or docker.java"
    else
      null;
  javaSuffix =
    if hasMcVersion then
      ":java${toString (javaForVersion cfg.version)}"
    else if hasJavaVersion then
      ":java${d.java}"
    else
      "";

  baseEnv = import ./compose-general.nix { inherit cfg lib bool; };
  hostingEnv = import (./. + "/compose-${cfg.type}.nix") { inherit cfg lib name; };

  volumes = [
    "./data:/data"
    "./pack:/pack"
    "./world:/data/world"
  ];

  doc = {
    services.mc = {
      image = "itzg/minecraft-server${javaSuffix}";
      container_name = "minecraft-${name}";
      stdin_open = true;
      tty = true;
      ports = [ "${toString d.port}:25565" ];
      env_file = [
        {
          # runtime cf zip thing
          path = ".env";
          required = false;
        }
        {
          # runtime cf zip thing
          path = ".env.runtime";
          required = false;
        }
      ];
      environment = baseEnv // hostingEnv // cfg.extraEnv;
      inherit volumes;
      restart = d.restart;
    };
  };
in
yaml.generate "compose-${name}.yaml" doc
