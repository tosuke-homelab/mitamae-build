{
  pkgs,
  stdenv,
}: let
  ocis = pkgs.callPackage ./image.nix {};

  images = with ocis; [
    {
      dist = linux-x86_64;
      platform = {
        os = "linux";
        architecture = "amd64";
      };
    }
    {
      dist = linux-i386;
      platform = {
        os = "linux";
        architecture = "386";
      };
    }
    {
      dist = linux-armhf;
      platform = {
        os = "linux";
        architecture = "arm";
        variant = "v6";
      };
    }
    {
      dist = linux-aarch64;
      platform = {
        os = "linux";
        architecture = "arm64";
        variant = "v8";
      };
    }
    {
      dist = linux-mips;
      platform = {
        os = "linux";
        architecture = "mips";
      };
    }
  ];
in
  stdenv.mkDerivation {
    name = "oci-image";

    src = ./.;

    nativeBuildInputs = with pkgs; [jq skopeo oras];

    images = builtins.toJSON images;

    buildPhase = ''
      function manifests {
        local dist
        for image in $(echo $images | jq -c ".[]"); do
          dist=$(echo $image | jq -r ".dist")
          jq -n \
            --arg digest $(skopeo manifest-digest "$dist/manifest.json") \
            --arg size $(wc --bytes "$dist/manifest.json" | cut -d" " -f1) \
            --argjson platform $(echo $image | jq -c ".platform") \
            '{
              "mediaType": "application/vnd.oci.image.manifest.v1+json",
              "digest": $digest,
              "size": $size | tonumber,
              "platform": $platform
            }'
        done
      }

      jq -n \
        --argjson manifests $(manifests | jq -sc .) \
        '{
          "schemaVersion": 2,
          "mediaType": "application/vnd.oci.image.index.v1+json",
          "manifests": $manifests
        }' > index.json

      mkdir oci
      for dist in $(echo $images | jq -r ".[].dist"); do
        skopeo copy --insecure-policy "oci:$dist/oci" oci:oci
      done
      rm oci/index.json
      oras manifest push --oci-layout oci index.json
    '';

    installPhase = ''
      mkdir -p $out

      cp -r oci $out
    '';
  }
