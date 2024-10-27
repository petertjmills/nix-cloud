{ 
  lib, 
  buildNpmPackage, 
  fetchFromGitHub,
  defaultHostname ? "0.0.0.0",
  defaultPort ? 3000 
}:

buildNpmPackage rec {
  pname = "financeTracker";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "petertjmills";
    repo = pname;
    rev = "main";
    hash = "sha256-b09a7a9471262b7e7c8864938d7363133ba03bc3";
  };

  npmDepsHash = "sha256-ZsPv2vE8KtJlmb1Q3cI7LYU2jauyrG8IkXbU4TCH7TQ=";

  postBuild = ''
    
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -r . $out/bin

    runHook postInstall
  '';

  meta = {
    description = "Personal Finance tracker";
  };
}