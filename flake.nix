{
  description = "rescript frontend";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=23.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  #clientsha sha256-jlEObGj4f/CoxGaRZfc10rnX/IHn0ZM3Ik1UX9Aa1uk=
  #serversha sha256-xxGELwjKIGRK1/a8P7uvUCKrP9y8kqAHSBfi2/IsebU=
  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        rescript-language-server-client = pkgs.buildNpmPackage rec {
          name = "rescript vscode lsp client";
          version = "1.50.0";
          src = pkgs.fetchgit {
            url = "https://github.com/rescript-lang/rescript-vscode/archive/refs/tags/1.50.0.tar.gz";
            sparseCheckout = [
              "client"
            ];
          };
          dontNpmBuild = true;
          dontNpmInstall = true;
          npmPackFlags = [ "--ignore-scripts" ];
          npmDepsHash = "sha256-jlEObGj4f/CoxGaRZfc10rnX/IHn0ZM3Ik1UX9Aa1uk=";
          buildPhase = ''echo "building client"'';
          installPhase = ''echo "installing client"'';
        };
        rescript-language-server-server = pkgs.buildNpmPackage rec {
          name = "rescript vscode lsp server";
          version = "1.50.0";
          src = pkgs.fetchgit {
            url = "https://github.com/rescript-lang/rescript-vscode/archive/refs/tags/1.50.0.tar.gz";
            sparseCheckout = [
              "server"
            ];
          };
          dontNpmBuild = true;
          dontNpmInstall = true;
          npmPackFlags = [ "--ignore-scripts" ];
          npmDepsHash = "sha256-xxGELwjKIGRK1/a8P7uvUCKrP9y8kqAHSBfi2/IsebU=";
          buildPhase = ''echo "building server"'';
          installPhase = ''echo "installing server"'';
        };
        rescript-language-server = pkgs.buildNpmPackage rec {
          dontNpmBuild = true;
          dontNpmInstall = true;
          npmPackFlags = [ "--ignore-scripts" ];
          name = "rescript vscode language server protocol";
          version = "1.50.0";
          src = pkgs.fetchFromGitHub {
            owner = "rescript-lang";
            repo = "rescript-vscode";
            rev = "1.50.0";
            hash = "sha256-4b2Z94/CCvPge9qKmv8svUib8zJ9NEZ+FYeylgmkKBQ=";
          };
          npmDepsHash = "sha256-J5B/E3x5A1WAZRYPOVHXTuAWLj9laawvB/mqzmryCko=";
# cd server && npm i
# && cd ../client && npm i
# && cd ../tools && npm i && cd ../tools/tests && npm i
# && cd ../../analysis/tests && npm i
# && cd ../reanalyze/examples/deadcode && npm i
# && cd ../termination && npm i
          buildPhase = ''echo "building main project "'';
          installPhase = let disablePostInstallReason = "disabled postinstall to not build tools directory";
            in  ''
                  echo "hello from install phase" &&\
                  pushd server && npm i\
                  && popd && pushd client && npm i\
                  && popd\
                  && npm pkg set scripts.postinstall="${disablePostInstallReason}"\
                  && npm i
                '';
          meta = {
            description = "rescript language server";
            homepage = "https://rescript-lang.org/";
            license = "MIT";
            maintainers = [];
          };
        };
      in {
        packages.default = rescript-language-server;
      }
    );
}
