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
        rescript-analysis-package = pkgs.ocamlPackages.buildDunePackage rec {
          pname = "analysis";
          version = "0.0.1";
          src = rescript-vscode;
          nativeBuildInputs = [
            # this (cppo) had to be nativeBuildInputs and not buildInputs
            pkgs.ocamlPackages.cppo
          ];
          #buildPhase = ''
          #  echo "in dune build phase"
          #'';
        };
        rescript-vscode-package =
          let
            #clientNpmDepsHash = "sha256-jlEObGj4f/CoxGaRZfc10rnX/IHn0ZM3Ik1UX9Aa1uk=";
            #clientDeps = pkgs.fetchNpmDeps {
            #};
            serverDeps = pkgs.fetchNpmDeps {
              src = "${rescript-vscode}/server";
              hash = "sha256-xxGELwjKIGRK1/a8P7uvUCKrP9y8kqAHSBfi2/IsebU=";
            };
            topLevelPackageNpmDepsHash = "sha256-J5B/E3x5A1WAZRYPOVHXTuAWLj9laawvB/mqzmryCko=";
            mkLspCommand = outDirPath: (pkgs.writeShellScript "rescript-language-server" ''
              ${outDirPath}/server/out/cli.js
              '');
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
              cp -r ${rescript-vscode}/* $out
              ##echo "copied server deps to cache dir"
              echo "set npm cach directory printing npm's cache config setting below:"
              HOME=$PWD npm config get cache
              chmod -R +w $out/server
              cd $out/server
              echo "running npm ci at $(pwd)"
              HOME=$PWD npm ci
              cd ..
              HOME=$PWD npm run bundle-server
############# use dune to build analysis directory
              ls ${rescript-analysis-package}/bin
#TODO production binary install folder 'linux' would be different on macos or windows
#move the analysis binary to the folder that the javascript language server expects it to be in
              mkdir -p $out/server/src/analysis_binaries/linux
              cp ${rescript-analysis-package}/bin/rescript-editor-analysis $out/server/src/analysis_binaries/linux/rescript-editor-analysis.exe
            '';
            installPhase = ''
              echo "installing it"
              echo "install phase working directory is $(pwd)"
              mkdir -p $out/bin
              cp ${mkLspCommand (placeholder "out")} $out/bin/rescript-language-server
              # TODO this probably isn't necessary, I think the 'server' directory exists in $out even if I don't copy it to $out/bin
              cp -r $out/server $out/bin/server
            '';
            wrapperPath = nixpkgs.lib.strings.makeBinPath [
              # the LSP will need NODE to be able to execute the server
              nodejs_20
            ];
            postFixup = ''
              wrapProgram $out/server/out/cli.js \
              --set PATH $wrapperPath
            '';
          });
      in rec {
        packages.default = rescript-vscode-package;
        apps.rescript-language-server = {
          type = "app";
          program = "${self.packages.${system}.default}/bin/rescript-language-server";
        };
        apps.default = apps.rescript-language-server;
      }
    );
}
