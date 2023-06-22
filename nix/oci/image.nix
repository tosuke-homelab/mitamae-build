{
  pkgs,
  stdenv,
}: let
  mitamaes = pkgs.callPackage ../mitamae {};
  names = ["linux-x86_64" "linux-i386" "linux-armhf" "linux-aarch64"];
  entries =
    builtins.map (name: {
      inherit name;
      value = stdenv.mkDerivation {
        name = "oci-${name}";

        src = mitamaes.${name};
        nativeBuildInputs = [pkgs.oras];

        buildPhase = ''
          mkdir oci
          tar -czf mitamae.tar.gz mitamae
          oras push --export-manifest manifest.json --oci-layout oci mitamae.tar.gz:application/vnd.oci.image.layer.v1.tar+gzip
        '';

        installPhase = ''
          mkdir -p $out

          cp -r oci $out
          cp manifest.json $out/manifest.json
        '';
      };
    })
    names;
in
  builtins.listToAttrs entries
