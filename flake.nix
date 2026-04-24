{
  description = "Minecraft server fleet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Auto-discover servers/*.yaml at eval time
        serverDir = builtins.readDir ./servers;
        yamlFiles = builtins.filter (
          name: serverDir.${name} == "regular" && builtins.match ".*\\.yaml$" name != null
        ) (builtins.attrNames serverDir);

        stripExt = name: builtins.substring 0 (builtins.stringLength name - 5) name;

        makeDeployApp =
          yamlFile:
          let
            name = stripExt yamlFile;
            composeSrc = ./servers + "/${yamlFile}";
          in
          {
            type = "app";
            program = toString (
              pkgs.writeShellApplication {
                name = "deploy-${name}";
                runtimeInputs = [
                  pkgs.coreutils
                  pkgs.gnugrep
                ];
                text = ''
                  set -euo pipefail

                  # key check (do this first, fail fast)
                  KEY_FILE="$HOME/mc-servers/key.txt"
                  if [ ! -f "$KEY_FILE" ]; then
                    echo "✗ $KEY_FILE not found."
                    echo "  Create it with a single line: CF_API_KEY=your_curseforge_key"
                    echo "  Replace every '$' with '$$'"
                    mkdir "$HOME/mc-servers"
                    exit 1
                  fi

                  # stop running minecraft containers
                  echo "━━━ Stopping running minecraft/mc containers ━━━"
                  CONTAINERS=$(docker ps --format '{{.Names}}' \
                    | grep -E '^(minecraft-|mc-)' || true)

                  if [ -n "$CONTAINERS" ]; then
                    echo "[docker] Stopping: $CONTAINERS"
                    echo "$CONTAINERS" | xargs docker stop --time 60
                    echo "[docker] All stopped."
                  else
                    echo "[docker] Nothing running, continuing."
                  fi

                  # set up server dir
                  DEST="$HOME/mc-servers/${name}"
                  echo ""
                  echo "━━━ Deploying ${name} → $DEST ━━━"
                  mkdir -p "$DEST"
                  rm -f "$DEST/compose.yaml" # need to delete cuz its readonly
                  cp ${composeSrc} "$DEST/compose.yaml"
                  cp "$KEY_FILE" "$DEST/.env"

                  # check if compose uses CF_MODPACK_ZIP
                  # grep -E should skip commented lines (leading #, ignoring whitespace)
                  if grep -qE '^[[:space:]]*CF_MODPACK_ZIP:' "$DEST/compose.yaml"; then
                    if [ -f "$DEST/pack/modpack.zip" ]; then
                      echo "[zip] modpack.zip detected."
                    else
                      mkdir -p "$DEST/pack"
                      SLUG=$(grep -E '^[[:space:]]*CF_SLUG:' "$DEST/compose.yaml" \
                        | head -1 \
                        | sed 's/.*CF_SLUG:[[:space:]]*//' \
                        | tr -d '"'"'"' ')
                      URL="https://www.curseforge.com/minecraft/modpacks/$SLUG"

                      echo ""
                      echo "┌─────────────────────────────────────────────────────┐"
                      echo "│  This server needs a modpack zip.                   │"
                      echo "│                                                     │"
                      echo "│  Opening modpack URL...                             │"
                      echo "│                                                     │"
                      echo "│  Manually download the modpack zip                  │"
                      echo "│  Watching ~/Downloads...                            │"
                      echo "└─────────────────────────────────────────────────────┘"

                      if command -v xdg-open >/dev/null; then
                        xdg-open "$URL" >/dev/null 2>&1
                      elif command -v open >/dev/null; then # fallback for macOS
                        open "$URL" >/dev/null 2>&1
                      else
                        echo "Could not detect web browser. Please open the link manually."
                        echo "$URL"
                      fi

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
                            echo "[zip] Found new download: $(basename "$zip")"
                            echo "[zip] Successfully moved to: $DEST/pack/modpack.zip"

                            break 2
                          fi
                        done

                        sleep 2
                      done

                      shopt -u nullglob
                    fi
                  fi

                  # bring it up
                  cd "$DEST"
                  docker compose up -d --build

                  echo ""
                  echo "✓ ${name} is up. Logs: docker compose -f $DEST/compose.yaml logs -f" # TODO: add attach command
                '';
              }
              + "/bin/deploy-${name}"
            );
          };

      in
      {
        devShells.default = pkgs.mkShell {
          name = "MC Fleet";
          packages = [
            pkgs.fish
            pkgs.docker-compose-language-service # docker compose schema & completions
            pkgs.yaml-language-server # general YAML (set schema in editor)
          ];
          shellHook = ''
            if [ -z "$FISH_VERSION" ]; then
              exec fish
            fi
          '';
        };

        # nix run .#aero / nix run .#souls / etc — one per yaml, auto-discovered
        apps = builtins.listToAttrs (
          map (yamlFile: {
            name = stripExt yamlFile;
            value = makeDeployApp yamlFile;
          }) yamlFiles
        );
      }
    );
}
