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
            clientNpmDepsHash = "sha256-jlEObGj4f/CoxGaRZfc10rnX/IHn0ZM3Ik1UX9Aa1uk=";
            serverNpmDepsHash = "sha256-xxGELwjKIGRK1/a8P7uvUCKrP9y8kqAHSBfi2/IsebU=";
            topLevelPackageNpmDepsHash = "sha256-J5B/E3x5A1WAZRYPOVHXTuAWLj9laawvB/mqzmryCko=";
          in (with pkgs; stdenv.mkDerivation {
            name = "rescript vscode lsp server";
            version = "1.50.0";
            src = rescript-vscode;
            buildPhase = ''
              echo "building it"
              touch $out
            '';
            installPhase = ''
              echo "installing it"
            '';
          });
      in {
        packages.default = rescript-vscode-package;
      }
    );
}
