final: prev: {
  nexttest = prev.callPackage ./test.nix { };
  workerd = prev.callPackage ./workerd.nix { };
}