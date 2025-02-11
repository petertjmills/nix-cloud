{ 
  lib, 
  stdenv,
  fetchurl,
  nodejs,
  autoPatchelfHook,
  llvmPackages,
  musl,
  xorg,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "workerd";
  version = "1.20240718.0";

  src = {
    x86_64-linux = fetchurl {
      url = "https://github.com/cloudflare/workerd/releases/download/v${finalAttrs.version}/workerd-linux-64.gz";
      hash = "sha256-qnIQsNKEDTZDnZKFc2LW3phDmJTrHgfbdWWCtqd2k+g=";
    };
  }.${stdenv.hostPlatform.system} or (throw "Unsupported system: ${stdenv.hostPlatform.system}");

  dontUnpack = true;
  dontConfigure = true;
  dontBuild = true;

  buildInputs = [
    llvmPackages.libcxx
    llvmPackages.libunwind
    musl
    xorg.libX11
  ];

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    nodejs
  ];

  installPhase = ''
    mkdir -p $out/bin
    gunzip -c $src > $out/bin/workerd
    chmod +x $out/bin/workerd
  '';

  meta = with lib; {
    homepage = "https://github.com/cloudflare/workerd";
    description = "workerd";
    license = licenses.asl20;
    platforms = [ "x86_64-linux" ];
    # maintainers = with maintainers; [  ];
    mainProgram = "workerd";
  };
})