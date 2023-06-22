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

        bins = pkgs.callPackage ./nix/mitamae {};
        oci-images = pkgs.callPackage ./nix/oci/image.nix {};
        oci-index = pkgs.callPackage ./nix/oci/index.nix {};

        packages = with builtins; let
          names = import ./nix/mitamae/targets.nix;
          multiarch-bin-entries =
            map (name: {
              name = "bin-" + name;
              value = bins.${name};
            })
            names;
          oci-entries =
            map (name: {
              name = "oci-" + name;
              value = oci-images.${name};
            })
            names;
        in
          listToAttrs ([
              {
                name = "bin-host";
                value = bins.host;
              }
            ]
            ++ multiarch-bin-entries
            ++ oci-entries
            ++ [
              {
                name = "oci";
                value = oci-index;
              }
            ]);
      in {
        apps.skopeo = with pkgs; {
          type = "app";
          program = "${pkgs.skopeo}/bin/skopeo";
        };
        packages =
          packages
          // {
            default = packages.bin-host;
          };

        formatter = treefmt;
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            oras
            skopeo
          ];
        };
      }
    );
}
