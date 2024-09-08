let
  cirrus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIJEb+DrAiF+r2VH8Rk0O3hrkrcUZ26As6Iok/xAPgi6";
  cumulus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPEhVfbVbix9lPz1+hQAeo7qRtQwIs6+ev22HLa4IiI+";
  stratus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAantcVH8/va/b0q8fPNsVLxwTeebFGOtxVVWYXIpEPM";
in {
  "cirrus_wireguard_private_key.age".publicKeys = [
    cirrus
  ];
  "stratus_wireguard_private_key.age".publicKeys = [
    stratus
  ];
  "iphone_wireguard_private_key.age".publicKeys = [
    cumulus
  ];
}