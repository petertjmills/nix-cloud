# { lib
# , defaultHostname ? "0.0.0.0"
# , defaultPort ? 3000
# , pnpm
# , nodejs
# , stdenv
# }:

# stdenv.mkDerivation (finalAttrs: {
#   pname = "finance-tracker-next";
#   version = "0.0.1";

#   src = builtins.fetchGit {
#     url = "git@github.com:petertjmills/finance-tracker-next.git";
#     ref = "main";
#     rev = "c41e5cc058a8af263705fcdd5a2822c44a6eb856";
#   };

#   buildInputs = [
#     nodejs
#   ];

#   nativeBuildInputs = [
#     pnpm.configHook
#   ];

#   pnpmDeps = pnpm.fetchDeps {
#     inherit (finalAttrs) pname version src;
#     hash = "sha256-1SXGmhpKw9wi5B7B+Bwbxz0pZ9WA3v1+9ufQunCncdg=";
#   };

#   buildPhase = ''
#     runHook preBuild
    
#     pnpm build

#     runHook postBuild
#   '';

#   postBuild = ''
    
#   '';

#   installPhase = ''
#     runHook preInstall

#     mkdir -p $out/bin
#     cp -r . $out/bin

#     runHook postInstall
#   '';

#   meta = {
#     description = "Personal Finance tracker";
#   };
# })
