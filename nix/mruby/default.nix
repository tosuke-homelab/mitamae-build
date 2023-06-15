{
  stdenv,
  fetchFromGitHub,
  ...
}:
stdenv.mkDerivation {
  name = "mruby";

  src = fetchFromGitHub {
    owner = "mruby";
    repo = "mruby";
    rev = "3.0.0";
    sha256 = "sha256-C3K7ZooaOMa+V2HjxwiKxrrMb7ffl4QAgPsftRtb60c=";
  };

  dontBuild = true;

  patches = [
    ./mruby3.0.0-gems-fix.diff
    ./mruby3.0.0-disable-checkout.diff
  ];

  installPhase = ''
    mkdir -p $out
    cp -r . $out
  '';
}
