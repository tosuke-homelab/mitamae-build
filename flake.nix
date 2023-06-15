{
  description = "mitamae";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    flake-compat.url = "github:edolstra/flake-compat";
    flake-compat.flake = false;
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    treefmt-nix,
    ...
  }:
    flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
        treefmt = treefmt-nix.lib.mkWrapper pkgs {
          projectRootFile = "flake.nix";
          programs.alejandra.enable = true;
        };

        mitamae-x = pkgs.callPackage ./nix/mitamae {};
      in {
        packages.default = mitamae-x;

        formatter = treefmt;
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            yq
            upx
            oras
            skopeo
          ];
        };
      }
    );
}
