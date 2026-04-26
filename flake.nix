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

        serverDir = builtins.readDir ./servers;
        serverNames = builtins.filter (name: serverDir.${name} == "directory") (
          builtins.attrNames serverDir
        );

        makeCompose = import ./nix/compose.nix { inherit pkgs; };
        makeDeployApp = import ./nix/deploy.nix { inherit pkgs; };
        makeIconApp = import ./nix/icon.nix { inherit pkgs; };

        makeServerApp =
          name:
          let
            configPath = ./servers + "/${name}/config.nix";
            cfg = if builtins.pathExists configPath then import configPath else { };
            composeSrc = makeCompose name cfg;
          in
          makeDeployApp name composeSrc cfg;

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
              value = makeServerApp name;
            }) serverNames
          )
          // {
            icon = makeIconApp;
          };
      }
    );
}
