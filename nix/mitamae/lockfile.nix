{
  pkgs,
  stdenv,
  ...
}: let
  lock = import ./lock.nix;

  lockSection = with builtins; let
    lockValues = attrValues lock;
    lockEntries =
      map ({
        url,
        commit,
        branch,
        version,
        ...
      }: {
        name = url;
        value = {inherit url commit branch version;};
      })
      lockValues;
  in
    listToAttrs lockEntries;

  lockfile = {
    mruby = {
      version = "3.0.0";
      release_no = 30000;
    };
    builds = {
      host = lockSection;
      linux-aarch64 = lockSection;
    };
  };
in
  stdenv.mkDerivation {
    name = "mitamae-lockfile";

    dontBuild = true;
    dontUnpack = true;

    buildInputs = [pkgs.yq];
    content = builtins.toJSON lockfile;

    installPhase = ''
      mkdir -p $out
      echo $content | yq -y . > $out/build_config.rb.lock
    '';
  }
