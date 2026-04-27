{ pkgs, lib }: # Jesus
let
  yaml = pkgs.formats.yaml { };
  bool = b: if b then "TRUE" else "FALSE";
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

  baseEnv = import ./compose-general.nix { inherit cfg lib bool; };
  hostingEnv = import (./. + "/compose-${cfg.type}.nix") { inherit cfg lib name; };
  volumes = [
    "./data:/data"
    "./pack:/pack"
  ];

  doc = {
    services.mc = {
      image = "itzg/minecraft-server:java${toString d.java}";
      container_name = "minecraft-${name}";
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
