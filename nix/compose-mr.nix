{
  lib,
  cfg,
  name,
  ...
}:

let
  # sanity checks
  localModpack = ../servers + "/${name}/modpack.mrpack";
  hasLocal = builtins.pathExists localModpack;
  hasSlug = cfg.slug != "";

  _ = if !hasSlug && !hasLocal then throw "No modpack file or slug provided" else null;
  __ = if hasSlug && hasLocal then throw "Both modpack and slug found. Choose one" else null;

  env = {
    TYPE = "MODRINTH";
  }
  // lib.optionalAttrs hasSlug { MODRINTH_MODPACK = cfg.slug; }
  // lib.optionalAttrs hasLocal { MODRINTH_MODPACK = "/pack/modpack.mrpack"; }
  // lib.optionalAttrs (cfg.addMods != "") { MODRINTH_PROJECTS = cfg.addMods; }
  // lib.optionalAttrs (cfg.removeMods != "") { MODRINTH_EXCLUDE_FILES = cfg.removeMods; };
in
env
