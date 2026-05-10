{
  lib,
  cfg,
  name,
  ...
}:

let
  # sanity checks
  # TODO: manifest support
  localModpack = ../servers + "/${name}/modpack.zip";
  hasLocal = builtins.pathExists localModpack;
  hasSlug = cfg.slug != "";

  _ = if !hasSlug && !hasLocal then throw "No modpack file or slug provided" else null;
  __ = if hasSlug && hasLocal then throw "Both modpack and slug found. Choose one" else null;

  env = {
    TYPE = "AUTO_CURSEFORGE";
  }
  // lib.optionalAttrs hasSlug { CF_SLUG = cfg.slug; }
  // lib.optionalAttrs hasLocal { CF_MODPACK_ZIP = "/pack/modpack.zip"; }
  // lib.optionalAttrs (cfg.addMods != "") { CURSEFORGE_FILES = cfg.addMods; }
  // lib.optionalAttrs (cfg.removeMods != "") { # this needs to be space separated
    CF_EXCLUDE_MODS = builtins.concatStringsSep " " (
      builtins.filter (s: s != "") (map lib.trim (lib.splitString "\n" cfg.removeMods))
    );
  };
in
env
