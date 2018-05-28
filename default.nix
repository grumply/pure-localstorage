{ mkDerivation, base, pure-json, pure-lifted, pure-txt, stdenv
, unordered-containers
}:
mkDerivation {
  pname = "pure-localstorage";
  version = "0.7.0.0";
  src = ./.;
  libraryHaskellDepends = [
    base pure-json pure-lifted pure-txt unordered-containers
  ];
  homepage = "github.com/grumply/pure-localstorage";
  license = stdenv.lib.licenses.bsd3;
}
