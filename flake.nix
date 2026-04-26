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
        serverNames = builtins.filter (name: serverDir.${name} == "directory") (
          builtins.attrNames serverDir
        );

        makeDeployApp = import ./nix/deploy.nix { inherit pkgs; };
        makeIconApp = import ./nix/icon.nix { inherit pkgs; };

      in
      {
        devShells.default = pkgs.mkShell {
          name = "MC Fleet";
          packages = [
            pkgs.fish
            pkgs.docker-compose-language-service # docker compose schema & completions
            pkgs.yaml-language-server # general YAML (set schema in editor)
          ];
        };

        # nix run .#aero / nix run .#souls / etc — one per yaml, auto-discovered
        apps =
          builtins.listToAttrs (
            map (name: {
              inherit name;
              value = makeDeployApp name;
            }) serverNames
          )
          // {
            icon = makeIconApp;
          };
      }
    );
}
