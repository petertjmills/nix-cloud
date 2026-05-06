{
  fetchPnpmDeps,
  nodejs,
  pnpm_10,
  pnpmConfigHook,
  stdenv,
  lib,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "used-teslas-website";
  version = "0.0.1";

  src = ../../web/site;

  nativeBuildInputs = [
    nodejs
    pnpmConfigHook
    pnpm_10
  ];

  pnpmDeps = fetchPnpmDeps {
    inherit (finalAttrs) pname version src;
    pnpm = pnpm_10;
    fetcherVersion = 1;
    hash = lib.fakeHash;
  };

  buildPhase = ''
    runHook preBuild
    pnpm build
    runHook postBuild
  '';

  installPhase = ''
        runHook preInstall

        mkdir -p $out
        cp -r dist $out/
        cp -r node_modules $out/
        cp package.json $out/

        # Create a wrapper script
        mkdir -p $out/bin
        cat > $out/bin/${finalAttrs.pname} <<EOF
    #!/bin/sh
    cd $out
    exec ${nodejs}/bin/node $out/dist/server/entry.mjs "\$@"
    EOF
        chmod +x $out/bin/${finalAttrs.pname}

        runHook postInstall
  '';

  meta = with lib; {
    description = "Used Teslas UK website built with Astro";
    license = licenses.mit;
    maintainers = [ ];
    platforms = platforms.all;
  };
})
