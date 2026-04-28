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
  pilotSnippet = import ./pilot.nix { inherit name; };
  finishSnippet = import ./finish.nix { inherit name; };
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
        rm -f "$DEST/.env.runtime"

        echo ""
        ${preFlight}
        ${iconSnippet}
        ${dockerSnippet}
        ${pilotSnippet}
        ${finishSnippet}
      '';
    }
    + "/bin/deploy-${name}"
  );
}
