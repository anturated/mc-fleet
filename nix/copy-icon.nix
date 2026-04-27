{ name }:

let
  serverIcon = ../servers + "/${name}/server-icon.png";
  hasIcon = builtins.pathExists serverIcon;

  script =
    if hasIcon then
      ''
        echo "• ───────────────────── Icon ───────────────────── •"
        echo "> Copying server-icon.png..."
        mkdir -p "$DEST/data"
        rm -f "$DEST/data/server-icon.png"
        cp ${serverIcon} "$DEST/data/server-icon.png"
      ''
    else
      ''
        if [ -f "$DEST/data/server-icon.png" ]; then
          echo "> No server-icon in repo, removing the old one..."
          rm -f "$DEST/data/server-icon.png"
        fi
      '';
in
script
