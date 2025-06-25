{
  # lib,
  # fetchFromGitHub,
  # buildGoModule,
  pkgs,
}:

pkgs.buildGoModule rec {
  pname = "tldx";
  version = "v1.2.4";

  src = pkgs.fetchFromGitHub {
    owner = "brandonyoungdev";
    repo = "tldx";
    rev = version;
    hash = "sha256-inX/27nzju1ns6fKF3iFmgYOd8KpI/cLX+UM8LjeOVw=";
    # hash = pkgs.lib.fakeHash;
  };

  vendorHash = "sha256-gNU1YcvRXOvPsniZKE+XEQ7YaJTc5qjTRgCrnNMjfXw=";
  # vendorHash = pkgs.lib.fakeHash;

  meta = with pkgs.lib; {
    description = "Domain Availability Research Tool";
    homepage = "https://github.com/brandonyoungdev/tldx";
    maintainers = with maintainers; [

    ];
    mainProgram = "tldx";
    license = licenses.asl20;
  };
}
