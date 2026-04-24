{
  description = "Minecraft server fleet";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Auto-discover servers/*.yaml at eval time
        serverDir = builtins.readDir ./servers;
        yamlFiles = builtins.filter
          (name: serverDir.${name} == "regular" && builtins.match ".*\\.yaml$" name != null)
          (builtins.attrNames serverDir);

        stripExt = name: builtins.substring 0 (builtins.stringLength name - 5) name;

        makeDeployApp = yamlFile:
          let
            name = stripExt yamlFile;
            composeSrc = ./servers + "/${yamlFile}";
          in
          {
            type = "app";
            program = toString (pkgs.writeShellApplication {
              name = "deploy-${name}";
              # Don't pull docker from nix on Ubuntu — use the system one
              runtimeInputs = [ pkgs.coreutils pkgs.gnugrep ];
              text = ''
                set -euo pipefail

                echo "━━━ Stopping running minecraft/mc containers ━━━"
                CONTAINERS=$(docker ps --format '{{.Names}}' \
                  | grep -E '^(minecraft-|mc-)' || true)

                if [ -n "$CONTAINERS" ]; then
                  echo "Stopping: $CONTAINERS"
                  # 60s grace period; docker stop --time handles the SIGKILL fallback
                  echo "$CONTAINERS" | xargs docker stop --time 60
                  echo "All stopped."
                else
                  echo "Nothing running, continuing."
                fi

                DEST="$HOME/mc-servers/${name}"
                echo ""
                echo "━━━ Deploying ${name} → $DEST ━━━"
                mkdir -p "$DEST"
                cp ${composeSrc} "$DEST/compose.yaml"

                cd "$DEST"
                docker compose up -d --build

                echo ""
                echo "✓ ${name} is up. Logs: docker compose -f $DEST/compose.yaml logs -f"
              '';
            } + "/bin/deploy-${name}");
          };

      in
      {
        # nix develop  →  gets you docker-compose LSP + yaml-ls
        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.docker-compose-language-service  # docker compose schema & completions
            pkgs.yaml-language-server             # general YAML (set schema in editor)
          ];
        };

        # nix run .#aero / nix run .#souls / etc — one per yaml, auto-discovered
        apps = builtins.listToAttrs (map (yamlFile: {
          name = stripExt yamlFile;
          value = makeDeployApp yamlFile;
        }) yamlFiles);
      }
    );
}
