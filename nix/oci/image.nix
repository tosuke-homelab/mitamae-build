{
  pkgs,
  stdenv,
}: let
  platforms = {
    linux-x86_64 = {
      os = "linux";
      architecture = "amd64";
    };
    linux-i386 = {
      os = "linux";
      architecture = "386";
    };
    linux-armhf = {
      os = "linux";
      architecture = "arm";
      variant = "v6";
    };
    linux-aarch64 = {
      os = "linux";
      architecture = "arm64";
      variant = "v8";
    };
  };
  mitamaes = pkgs.callPackage ../mitamae {};
  mitamae-amd64-linux = mitamaes.linux-x86_64;
  config = {
    os = "linux";
    architecture = "amd64";
  };
  names = builtins.attrNames platforms;
  entries =
    builtins.map (name: {
      name = "oci-${name}";
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
