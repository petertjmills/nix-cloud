final: prev:
let
  inherit (final);
in
rec {
  nexttest = prev.callPackage ./test.nix { };
  workerd = prev.callPackage ./workerd.nix { };
  # finance-tracker = final.callPackage ./finance-tracker.nix { };
}
