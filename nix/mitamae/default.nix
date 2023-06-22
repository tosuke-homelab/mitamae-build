{
  pkgs,
  stdenv,
  fetchFromGitHub,
}: let
  mruby-src = pkgs.callPackage ../mruby {};
  lockfile = pkgs.callPackage ./lockfile.nix {};
  mitamae-src = stdenv.mkDerivation {
    name = "mitamae-src";

    src = fetchFromGitHub {
      owner = "itamae-kitchen";
      repo = "mitamae";
      rev = "v1.14.0";
      sha256 = "sha256-1U+adYeGBwyXvtvJOEXr4RjUWpjxb5Uhj45Ar4mGf/g=";
    };
    patches = [
      ./arch.diff
    ];

    dontBuild = true;

    buildInputs = [pkgs.jq];

    deps = with builtins;
      toJSON (
        map (name: {
          inherit name;
          src = mgems.${name};
        }) (attrNames mgems)
      );

    installPhase = ''
      mkdir -p $out
      cp -r . $out

      cp ${lockfile}/build_config.rb.lock $out

      mkdir -p $out/mruby
      cp -r ${mruby-src}/* $out/mruby

      for dep in $(echo $deps | jq -c ".[]"); do
        name=$(echo $dep | jq -r ".name")
        mkdir -p $out/mruby/build/repos/host/$name
        cp -r $(echo $dep | jq -r ".src")/* $out/mruby/build/repos/host/$name
      done
    '';
  };
  mgems =
    {
      mgem-list = pkgs.fetchFromGitHub {
        owner = "mruby";
        repo = "mgem-list";
        rev = "master";
        sha256 = "sha256-g+hfofayf/gRBqHtzDXoFWQI8Fzc1X1d8GFlHQYW270=";
      };
    }
    // builtins.mapAttrs (_: {
      url,
      commit,
      submodules,
      ...
    }:
      builtins.fetchGit {
        inherit url submodules;
        rev = commit;
      }) (import ./lock.nix);
  mitamae-src-for = {target}:
    pkgs.stdenv.mkDerivation {
      name = "mitamae-${target}-src";
      src = mitamae-src;

      dontBuild = true;

      installPhase = ''
        mkdir -p $out
        cp -r . $out

        if [ "${target}" != "host" ]; then
          mkdir -p $out/mruby/build/repos/${target}
          cp -r mruby/build/repos/host/* $out/mruby/build/repos/${target}
        fi
      '';
    };
  mitamae-for = {
    target,
    nativeBuildInputs,
    buildPhase,
  }:
    pkgs.stdenv.mkDerivation {
      name = "mitamae-${target}";

      src = mitamae-src-for {inherit target;};

      inherit nativeBuildInputs buildPhase;

      installPhase = ''
        mkdir $out
        cp mruby/build/${target}/bin/mitamae $out/mitamae
      '';
    };

  hostBuildInputs = with pkgs; [
    ruby
    rake
    autoconf
    automake
    libtool
    pkg-config
  ];

  mitamae-host = mitamae-for {
    target = "host";
    nativeBuildInputs = hostBuildInputs;
    buildPhase = ''
      unset LD # Don't use ld (see: https://github.com/mruby/mruby/blob/35be8b252495d92ca811d76996f03c470ee33380/tasks/toolchains/gcc.rake#L25)
      rake
    '';
  };

  mitamae-cross = {target}:
    mitamae-for {
      inherit target;
      nativeBuildInputs = hostBuildInputs ++ [pkgs.zig];
      buildPhase = ''
        unset LD
        export XDG_CACHE_HOME=$(mktemp -d) # Workaround for https://github.com/ziglang/zig/issues/6810
        rake compile BUILD_TARGET=${target}
      '';
    };
in
  with builtins; let
    targets = import ./targets.nix;
    cross-drvs-list =
      map (target: {
        name = target;
        value = mitamae-cross {inherit target;};
      })
      targets;
    cross-drvs = listToAttrs cross-drvs-list;
  in
    {
      host = mitamae-host;
    }
    // cross-drvs
