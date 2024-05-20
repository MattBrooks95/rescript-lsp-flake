{ pkgs, system }:
  let
    systemToBinaryDir = {
      "x86_64-linux" = "linux";
      "aarch64-darwin" = "darwin";
    };
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
    serverDeps = pkgs.fetchNpmDeps {
      src = "${rescript-vscode}/server";
      hash = "sha256-xxGELwjKIGRK1/a8P7uvUCKrP9y8kqAHSBfi2/IsebU=";
    };
    toolsDeps = pkgs.fetchNpmDeps {
      src = "${rescript-vscode}/tools";
      hash = "sha256-dVTeeICtCHXpHzemGmN8B9VEjz0BsVND6Ly5FT3vcvA=";
    };
    topLevelPackageNpmDepsHash = "sha256-J5B/E3x5A1WAZRYPOVHXTuAWLj9laawvB/mqzmryCko=";
  in pkgs.stdenv.mkDerivation rec {
      name = "rescript vscode lsp server";
      version = "1.50.0";
      src = rescript-vscode;
      buildInputs = [
        pkgs.nodejs_20
        # ideally we could just use the esbuild that gets installed by NPM
        # but the server's package.json's build script assumes esbuild is installed globally
        # TODO this might be better as a native build input, same for dune_3
        pkgs.esbuild
        # dune is used by buildDunePackage to build the ocaml dependencies, at least I think it is. The builder might not need this package?
        pkgs.dune_3
      ];
      nativeBuildInputs = [
        # this lets you use 'wrapProgram'
        pkgs.makeWrapper
      ];
      prePatch = ''
      echo "in prepatch"
      '';
      patches = [ ./constants.patch ];
      postPatch = ''
      echo "in postpatch"
      '';
      buildPhase = ''
        mkdir $out
        mkdir $PWD/.npm
        # TODO see if `HOME=$PWD npm config set cache="$PWD/.npm" works too
        # I looked at the buildNpmPackage nix source and saw them set it this way instead
        # and this way worked immediately
        export npm_config_cache="$PWD/.npm"
        cp -r ${serverDeps}/* $PWD/.npm
        chmod -R +w $PWD/.npm
        #cp -rf ${toolsDeps}/* $PWD/.npm
        cp -r server $out/server
        # cp -r tools $out/tools
        cp package.json $out/package.json
        HOME=$PWD npm config get cache
        chmod -R +w $out/server
        cd $out/server
        HOME=$PWD npm ci
        cd ..
        HOME=$PWD npm run bundle-server
        # chmod -R +w $out/tools
        # cd $out/tools
        # HOME=$PWD npm ci
      '';
      installPhase =
        let binDir = systemToBinaryDir.${system};
        in ''
          mkdir -p $out/bin/analysis_binaries/${binDir}
          cp ${rescript-analysis-package}/bin/rescript-editor-analysis $out/bin/analysis_binaries/${binDir}/rescript-editor-analysis.exe
          cp $out/server/out/cli.js $out/bin/rescript-language-server
        '';
    }
