final: prev: {
  opentofu = prev.opentofu.withPlugins (ps: with ps; [
    (
      mkProvider {
        hash = "sha256-dQvJVAxSR0eMeJseDR80MqXX4v7ry794bIr+ilpKBoQ=";
        owner = "Telmate";
        repo = "terraform-provider-proxmox";
        rev = "v3.0.1-rc6";
        vendorHash = "sha256-rD4+m0txQhzw2VmQ56/ZXjtQ9QOufseZGg8TrisgAJo=";
        spdx = "MIT";
        homepage = "https://registry.terraform.io/providers/Telmate/proxmox";
      }
    )
    hcloud
  ]);
}
