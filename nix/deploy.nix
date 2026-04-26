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

        R="$(tput setaf 1)"
        G="$(tput setaf 2)"
        Y="$(tput setaf 3)"
        B="$(tput setaf 4)"
        N="$(tput sgr0)"

        echo ""
        KEY_FILE="$HOME/mc-servers/key.txt"
        if [ ! -f "$KEY_FILE" ]; then
          echo "• ''${R}──────────────────── ERROR! ────────────────────''${N} •"
          echo "  $KEY_FILE not found."
          echo "  Create it with a single line:"
          echo "  CF_API_KEY='\$your\$curseforge\$keyyyyyyyyyyyyyyyy'"
          echo "  Your key can be found/created here:"
          echo "  ''${B}https://console.curseforge.com/#/api-keys''${N}"
          echo "• ''${R}────────────────────────────────────────────────''${N} •"
          mkdir -p "$HOME/mc-servers"
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

            echo -e "• ''${Y}────────────────────────────────────────────────''${N} •"
            echo -e "''${Y}  This server requires a modpack zip.''${N}"
            echo -e "''${Y}  Please download it manually.''${N}"
            if ''$OPENED; then
              echo -e "''${Y}  Opening CurseForge page in your browser...''${N}"
            else
              echo -e "''${Y}  No browser found. Open this link manually:''${N}"
              echo -e "''${Y}  ''$URL''${N}"
            fi
            echo -e "''${Y}  Watching ~/Downloads for a new .zip file...''${N}"
            echo -e "• ''${Y}────────────────────────────────────────────────''${N} •"

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
        echo "> Logs:"
        echo "    ''${G}docker compose -f $DEST/compose.yaml logs -f''${N}"
        echo "> Attach:"
        echo "    ''${G}docker attach minecraft-${name}''${N}"
        echo "• ──────────────────────────────────────────────── •"

        echo -ne "> What's next? (l)ogs / (a)ttach / (N)o action"


        read -n 1 -r choice
        echo  # move to next line after keypress

        case "$choice" in
          l|L)
            echo "> Opening logs for ${name}..."
            echo "• ──────────────────────────────────────────────── •"
            docker compose -f "$DEST/compose.yaml" logs -f
            ;;
          a|A)
            echo "> Attaching to ${name}..."
            echo "• ──────────────────────────────────────────────── •"
            docker attach "minecraft-${name}"
            ;;
          *)
            echo "> Goodbye."
            echo "• ──────────────────────────────────────────────── •"
            ;;
        esac
      '';
    }
    + "/bin/deploy-${name}"
  );
}
