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
      value = let
        config = platforms.${name};
      in
        stdenv.mkDerivation {
          name = "oci-${name}";

          src = mitamaes.${name};
          dontBuild = true;
          buildInputs = with pkgs; [jq oras];

          configJSON = builtins.toJSON config;

          installPhase = ''
            mkdir -p $out

            tar -zcvf mitamae.tar.gz mitamae

            echo $configJSON > config.json

            oras push --oci-layout $out --config config.json mitamae.tar.gz:application/vnd.oci.image.layer.v1.tar+gzip
          '';
        };
    })
    names;
in
  builtins.listToAttrs entries
