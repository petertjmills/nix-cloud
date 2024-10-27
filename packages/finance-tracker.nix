{ 
  lib, 
  buildNpmPackage, 
  fetchFromGitHub,
  defaultHostname ? "0.0.0.0",
  defaultPort ? 3000 
}:

buildNpmPackage rec {
  pname = "finance-tracker-next";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "petertjmills";
    repo = pname;
    rev = "main";
    hash = "sha256-b09a7a9471262b7e7c8864938d7363133ba03bc3";
  };

  npmDepsHash = "sha256-ZsPv2vE8KtJlmb1Q3cI7LYU2jauyrG8IkXbU4TCH7TQ=";

  postBuild = ''
    # Add a shebang to the server js file, then patch the shebang to use a nixpkgs nodejs binary.
    sed -i '1s|^|#!/usr/bin/env node\n|' .next/standalone/server.js
    patchShebangs .next/standalone/server.js
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{share,bin}

    cp -r .next/standalone $out/share/homepage/
    # cp -r .env $out/share/homepage/
    cp -r public $out/share/homepage/public

    mkdir -p $out/share/homepage/.next
    cp -r .next/static $out/share/homepage/.next/static

    chmod +x $out/share/homepage/server.js

    # we set a default port to support "nix run ..."
    makeWrapper $out/share/homepage/server.js $out/bin/nixtest #\
    #  --set-default PORT "3000" \
    #  --set-default HOSTNAME "0.0.0.0"

    runHook postInstall
  '';

  meta = {
    description = "Personal Finance tracker";
  };
}