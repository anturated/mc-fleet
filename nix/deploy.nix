{ pkgs }:
{
  name,
  cfg,
  composeSrc,
}:

let
  isCF = cfg.type == "cf";
  hasIcon = builtins.pathExists (../servers + "/${name}/server-icon.png");

  preFlight = if isCF then import ./preflight-cf.nix { inherit cfg; } else "";
  dockerSnippet = import ./docker-setup.nix { inherit name composeSrc; };
  iconSnippet = if hasIcon then import ./copy-icon.nix { inherit name; } else "";
in
{
  type = "app";
  program = toString (
    pkgs.writeShellApplication {
      name = "deploy-${name}";
      runtimeInputs = [ pkgs.coreutils ];
      text = ''
        set -euo pipefail

        R="$(tput setaf 1)"
        G="$(tput setaf 2)"
        Y="$(tput setaf 3)"
        B="$(tput setaf 4)"
        N="$(tput sgr0)"

        DEST="$HOME/mc-servers/${name}"
        mkdir -p "$DEST"

        echo ""
        ${preFlight}
        ${iconSnippet}
        ${dockerSnippet}
      '';
    }
    + "/bin/deploy-${name}"
  );
}
