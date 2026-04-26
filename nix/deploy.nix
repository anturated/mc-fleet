{ pkgs }:
name: composeSrc: cfg:
let
  lib = pkgs.lib;
  serverIcon = ../servers + "/${name}/server-icon.png";
  hasIcon = builtins.pathExists serverIcon;
  needsZip = cfg.zip or false;
  cfSlug = cfg.slug or "";
in
{
  type = "app";
  program = toString (
    pkgs.writeShellApplication {
      name = "deploy-${name}";
      runtimeInputs = [ pkgs.coreutils ];
      text = ''
        set -euo pipefail

        KEY_FILE="$HOME/mc-servers/key.txt"
        if [ ! -f "$KEY_FILE" ]; then
          echo "✗ $KEY_FILE not found."
          echo "  Create it with a single line: CF_API_KEY=your_curseforge_key"
          echo "  Replace every '$' with '$$'"
          mkdir "$HOME/mc-servers"
          exit 1
        fi

        echo "• ──────────────────── Docker ──────────────────── •"
        CONTAINERS=$(docker ps --format '{{.Names}}' \
          | grep -E '^(minecraft-|mc-)' || true)

        if [ -n "$CONTAINERS" ]; then
          echo "> Stopping $CONTAINERS"
          echo "$CONTAINERS" | xargs docker stop --timeout 60
          echo "> All stopped."
        else
          echo "> No minecraft containers running."
        fi

        DEST="$HOME/mc-servers/${name}"
        echo "> Deploying ${name}"
        mkdir -p "$DEST"
        rm -f "$DEST/compose.yaml" # need to delete cuz its readonly
        cp ${composeSrc} "$DEST/compose.yaml"
        cp "$KEY_FILE" "$DEST/.env"

        ${lib.optionalString needsZip ''
          if [ -f "$DEST/pack/modpack.zip" ]; then
            echo "> modpack.zip already present, skipping download."
          else
            rm -rf "$DEST/pack"
            mkdir -p "$DEST/pack"
            URL="https://www.curseforge.com/minecraft/modpacks/${cfSlug}"

            OPENED=false
            if   command -v xdg-open >/dev/null; then xdg-open "$URL" >/dev/null 2>&1 && OPENED=true
            elif command -v open     >/dev/null; then open     "$URL" >/dev/null 2>&1 && OPENED=true
            fi

            Y='\033[1;33m'
            R='\033[0m'
            echo -e "• ''${Y}────────────────────────────────────────────────''${R} •"
            echo -e "''${Y}  This server requires a modpack zip.''${R}"
            if ''$OPENED; then
              echo -e "''${Y}  Opening CurseForge page in your browser...''${R}"
            else
              echo -e "''${Y}  No browser found. Open this link manually:''${R}"
              echo -e "''${Y}  ''$URL''${R}"
            fi
            echo -e "''${Y}  Watching ~/Downloads for a new .zip file...''${R}"
            echo -e "• ''${Y}────────────────────────────────────────────────''${R} •"

            mkdir -p "$HOME/Downloads"
            shopt -s nullglob
            EXISTING_ZIPS=("$HOME/Downloads"/*.zip)
            while true; do
              CURRENT_ZIPS=("$HOME/Downloads"/*.zip)
              for zip in "''${CURRENT_ZIPS[@]}"; do
                is_new=true
                for e_zip in "''${EXISTING_ZIPS[@]}"; do
                  if [[ "$zip" == "$e_zip" ]]; then
                    is_new=false
                    break
                  fi
                done
                if $is_new; then
                  sleep 1
                  mv "$zip" "$DEST/pack/modpack.zip"
                  echo "> Moved $(basename "$zip") -> $DEST/pack/modpack.zip"

                  break 2
                fi
              done
              sleep 2
            done
            shopt -u nullglob
          fi
        ''}

        ${
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
            ''
        }

        cd "$DEST"
        docker compose up -d --build

        echo "• ───────────────────── Done ───────────────────── •"
        echo "> ${name} is up ✓"
        echo ">>>  Logs  <<<"
        echo "docker compose -f $DEST/compose.yaml logs -f"
        echo ">>> Attach <<<"
        echo "docker attach minecraft-${name}"
        echo "• ──────────────────────────────────────────────── •"
      '';
    }
    + "/bin/deploy-${name}"
  );
}
