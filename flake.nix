{
  description = "rescript frontend";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=23.11";
  };

  outputs = { self, nixpkgs, ... }@inputs:
    let
      forAllSystems = (function:
        nixpkgs.lib.genAttrs [
          "aarch64-darwin"
          "x86_64-linux"
        ] (system: function nixpkgs.legacyPackages.${system} system));
    in {
      packages = forAllSystems(pkgs: system:
        let
          rescript-lsp = import ./package.nix { inherit pkgs system; } ;
        in {
        default = rescript-lsp;
      });
    };
}
