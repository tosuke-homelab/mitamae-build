let
  mkLock = {
    url,
    commit,
    submodules ? false,
    branch ? "HEAD",
    version ? "0.0.0",
  }: {inherit url commit submodules branch version;};
in {
  mruby-at_exit = mkLock {
    url = "https://github.com/ksss/mruby-at_exit.git";
    commit = "09af1ecdce7b39582023c7614f8305386ee4d789";
  };

  mruby-dir = mkLock {
    url = "https://github.com/iij/mruby-dir.git";
    commit = "89dceefa1250fb1ae868d4cb52498e9e24293cd1";
  };

  mruby-dir-glob = mkLock {
    url = "https://github.com/gromnitsky/mruby-dir-glob.git";
    commit = "334c040a2e2c4c2689f8c3440168011f64d57ada";
  };

  mruby-env = mkLock {
    url = "https://github.com/iij/mruby-env.git";
    commit = "056ae324451ef16a50c7887e117f0ea30921b71b";
  };

  mruby-file-stat = mkLock {
    url = "https://github.com/ksss/mruby-file-stat.git";
    commit = "f3e858f01361b9b4a8e77ada52470068630c9530";
  };

  mruby-hashie = mkLock {
    url = "https://github.com/k0kubun/mruby-hashie.git";
    commit = "381741184e3382ebfa9aa40e6f02645494874df3";
  };

  mruby-json = mkLock {
    url = "https://github.com/mattn/mruby-json.git";
    commit = "f99d9428025469f2400f93c53b185f65f963e507";
  };

  mruby-open3 = mkLock {
    url = "https://github.com/k0kubun/mruby-open3.git";
    commit = "c2c269b07d0bc819be3e8bddd621429e59134de0";
  };

  mruby-optparse = mkLock {
    url = "https://github.com/fastly/mruby-optparse.git";
    commit = "e6397a090d1efe04d5dab57c63897f0d79bbad89";
  };

  mruby-shellwords = mkLock {
    url = "https://github.com/k0kubun/mruby-shellwords.git";
    commit = "2a284d99b2121615e43d6accdb0e4cde1868a0d8";
  };

  mruby-specinfra = mkLock {
    url = "https://github.com/k0kubun/mruby-specinfra.git";
    commit = "609ee8df4d2d4971d1a4efe0542137dab5bc4e01";
  };

  mruby-tempfile = mkLock {
    url = "https://github.com/k0kubun/mruby-tempfile.git";
    commit = "77736581bf971717aa2259144cf17bbb88b8d6b6";
  };

  mruby-yaml = mkLock {
    url = "https://github.com/mrbgems/mruby-yaml.git";
    commit = "123010195bf621e784ee9d4ff9144a4b8e9cbb6a";
    submodules = true;
  };

  mruby-erb = mkLock {
    url = "https://github.com/k0kubun/mruby-erb.git";
    commit = "978257e478633542c440c9248e8cdf33c5ad2074";
  };

  mruby-etc = mkLock {
    url = "https://github.com/eagletmt/mruby-etc.git";
    commit = "38eb1f9f12149d5919cf73bdced53fd9a2d9d254";
  };

  mruby-uri = mkLock {
    url = "https://github.com/zzak/mruby-uri.git";
    commit = "b3108ae56a48990eb7b79f44aca4ec76e1e60ad8";
  };

  mruby-schash = mkLock {
    url = "https://github.com/tatsushid/mruby-schash.git";
    commit = "c8470d4be2404b4cfbb8011daebc2ca9bb1cdb80";
  };

  mruby-errno = mkLock {
    url = "https://github.com/iij/mruby-errno.git";
    commit = "b4415207ff6ea62360619c89a1cff83259dc4db0";
  };

  mruby-process = mkLock {
    url = "https://github.com/iij/mruby-process.git";
    commit = "95da206a5764f4e80146979b8e35bd7a9afd6850";
  };

  mruby-catch-throw = mkLock {
    url = "https://github.com/IceDragon200/mruby-catch-throw";
    commit = "2b6eaff4232b4a9473b864df53c2917080af5dcf";
  };

  mruby-onig-regexp = mkLock {
    url = "https://github.com/mattn/mruby-onig-regexp.git";
    commit = "20ba3325d6fa504cbbf193e1b2a90e20fdab544f";
  };

  mruby-singleton = mkLock {
    url = "https://github.com/ksss/mruby-singleton.git";
    commit = "73dd4bae1a47d82e49b8f85bf27f49ec4462052e";
  };
}
