let
  cirrus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIJEb+DrAiF+r2VH8Rk0O3hrkrcUZ26As6Iok/xAPgi6";
  cumulus = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDwAl3UClnsvRzRWayeDbMVFWa1ez+uHRScbQxS6pa0Y";
in {
  "cirrus_wireguard_private_key.age".publicKeys = [
    cirrus
  ];
}