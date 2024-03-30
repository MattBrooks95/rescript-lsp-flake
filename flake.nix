{
  description = "rescript frontend";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=23.11";
  };

  outputs = { self, nixpkgs, flake-utils, ... }@inputs:
      let
        pkgs = nixpkgs.legacyPackages."x86_64-linux";
        rescript-vscode = pkgs.fetchFromGitHub {
          owner = "rescript-lang";
          repo = "rescript-vscode";
          rev = "1.50.0";
          hash = "sha256-4b2Z94/CCvPge9qKmv8svUib8zJ9NEZ+FYeylgmkKBQ=";
        };
        rescript-analysis-package = pkgs.ocamlPackages.buildDunePackage rec {
          pname = "analysis";
          version = "0.0.1";
          src = rescript-vscode;
          nativeBuildInputs = [
            # this (cppo) had to be nativeBuildInputs and not buildInputs
            pkgs.ocamlPackages.cppo
          ];
        };
        rescript-vscode-package =
          let
            serverDeps = pkgs.fetchNpmDeps {
              src = "${rescript-vscode}/server";
              hash = "sha256-xxGELwjKIGRK1/a8P7uvUCKrP9y8kqAHSBfi2/IsebU=";
            };
            toolsDeps = pkgs.fetchNpmDeps {
              src = "${rescript-vscode}/tools";
              hash = "sha256-dVTeeICtCHXpHzemGmN8B9VEjz0BsVND6Ly5FT3vcvA=";
            };
            topLevelPackageNpmDepsHash = "sha256-J5B/E3x5A1WAZRYPOVHXTuAWLj9laawvB/mqzmryCko=";
# this won't work because '.' is relative to where the command is executed from, not from where the bash script is
# all I need to do is to be able to call cli.js man.....
            #callCliShellScript = pkgs.writeShellScript "rescript-language-server" ''
            #./server/cli.js
            #'';
          in (with pkgs; stdenv.mkDerivation rec {
            name = "rescript vscode lsp server";
            version = "1.50.0";
            src = rescript-vscode;
            buildInputs = [
              nodejs_20
              # ideally we could just use the esbuild that gets installed by NPM
              # but the server's package.json's build script assumes esbuild is installed globally
              # TODO this might be better as a native build input, same for dune_3
              esbuild
              # dune is used by buildDunePackage to build the ocaml dependencies, at least I think it is. The builder might not need this package?
              dune_3
            ];
            nativeBuildInputs = [
              # this lets you use 'wrapProgram'
              pkgs.makeWrapper
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
              echo "done copying server NPM deps"
              chmod -R +w $PWD/.npm
              cp -rf ${toolsDeps}/* $PWD/.npm
              cp -r ${rescript-vscode}/* $out
              ##echo "copied server deps to cache dir"
              echo "set npm cach directory printing npm's cache config setting below:"
              HOME=$PWD npm config get cache
              chmod -R +w $out/server
              cd $out/server
              echo "running npm ci at $(pwd)"
              HOME=$PWD npm ci
              cd ..
              echo "bundling server"
              HOME=$PWD npm run bundle-server
              echo "building tools"
              chmod -R +w $out/tools
              cd $out/tools
              HOME=$PWD npm ci
############# use dune to build analysis directory
              ls ${rescript-analysis-package}/bin
#TODO production binary install folder 'linux' would be different on macos or windows
#move the analysis binary to the folder that the javascript language server expects it to be in
            '';
            installPhase = ''
              echo "installing it"
              echo "install phase working directory is $(pwd)"
              mkdir -p $out/bin
              mkdir -p $out/bin/analysis_binaries/linux
              cp ${rescript-analysis-package}/bin/rescript-editor-analysis $out/bin/analysis_binaries/linux/rescript-editor-analysis.exe
              # TODO this probably isn't necessary, I think the 'server' directory exists in $out even if I don't copy it to $out/bin
              mkdir -p $out/bin/server
              echo "made out/bin/server"
              cp $out/server/out/cli.js $out/bin/server/rescript-language-server
              cp ${rescript-analysis-package}/bin/rescript-editor-analysis $out/bin/rescript-editor-analysis.exe
              cp -r $out/tools $out/bin/tools
            '';
          });
      in rec {
        packages."x86_64-linux".default = rescript-vscode-package;
        apps.rescript-language-server = {
          type = "app";
          program = "${self.packages."x86_64-linux".default}/bin/rescript-language-server";
        };
        apps.default = apps.rescript-language-server;
      };
}
