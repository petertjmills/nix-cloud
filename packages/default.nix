final: prev: {
  nexttest = prev.callPackage ./test.nix { };
  workerd = prev.callPackage ./workerd.nix { };
  finance-tracker = prev.callPackage ./finance-tracker.nix { };
}