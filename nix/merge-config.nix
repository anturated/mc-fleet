{ lib }: # a totally normal and necessary nix file
let
  defaults = import ./defaults.nix;
in
{ userCfg }:
let
  cfg = lib.recursiveUpdate defaults userCfg;
in
cfg
