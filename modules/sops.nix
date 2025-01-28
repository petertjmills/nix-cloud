{ inputs, ... }:
{

  sops.defaultSopsFile = ../secrets/test.yaml;
  sops.age.sshKeyPaths = [ "/root/id_ed25519" ];
  sops.secrets.top_secret = {
  };
}
