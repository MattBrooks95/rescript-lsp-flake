{
  description = "rescript frontend";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=23.11";
    flake-utils.url = "github:numtide/flake-utils";
    rescript-vscode = {
      url = "github:rescript-lang/rescript-vscode?ref=1.50.0";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, flake-utils, rescript-vscode, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        rescript-vscode-package =
          let
            #clientNpmDepsHash = "sha256-jlEObGj4f/CoxGaRZfc10rnX/IHn0ZM3Ik1UX9Aa1uk=";
            #clientDeps = pkgs.fetchNpmDeps {
            #};
            serverDeps = pkgs.fetchNpmDeps {
              src = "${rescript-vscode}/server";
              hash =  "sha256-xxGELwjKIGRK1/a8P7uvUCKrP9y8kqAHSBfi2/IsebU=";
            };
            topLevelPackageNpmDepsHash = "sha256-J5B/E3x5A1WAZRYPOVHXTuAWLj9laawvB/mqzmryCko=";
          in (with pkgs; stdenv.mkDerivation {
            name = "rescript vscode lsp server";
            version = "1.50.0";
            src = rescript-vscode;
            buildInputs = [
              nodejs_20
              dune_3
            ];
            buildPhase = ''
              echo "building it"
              echo "buildPhase working directory $(pwd)"
              echo "home is $HOME"
              echo "PWD env variable:$PWD"
              echo "out is:$out"
              mkdir $out
              mkdir $PWD/.npm
              # TODO see if `HOME=$PWD npm config set cache="$PWD/.npm" works too
              # I looked at the buildNpmPackage nix source and saw them set it this way instead
              # and this way worked immediately
              export npm_config_cache="$PWD/.npm"
              echo "made npm cache dir"
              cp -r ${serverDeps}/* $PWD/.npm
              cp -r ${rescript-vscode}/* $out
              ##echo "copied server deps to cache dir"
              echo "set npm cach directory printing npm's cache config setting below:"
              HOME=$PWD npm config get cache
              chmod -R +w $out/server
              cd $out/server
              echo "running npm ci at $(pwd)"
              HOME=$PWD npm ci
              #HOME=. npm ci
              #HOME=$out npm install
            '';
            installPhase = ''
              echo "installing it"
              echo "install phase working directory is $(pwd)"
              ls
            '';
          });
      in {
        packages.default = rescript-vscode-package;
      }
    );
}
