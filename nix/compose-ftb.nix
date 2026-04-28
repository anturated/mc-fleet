{ cfg, ... }:

let
  hasSlug = cfg.slug != "";
  _ = if !hasSlug then throw "Slug is empty" else null;

  packId = builtins.head (builtins.match "([^-]+)(-.*)?$" cfg.slug);

  env = {
    TYPE = "FTBA";
    FTB_MODPACK_ID = packId;
  };
in
env
