{
  terranix,
  pkgs,
  nixpkgs,
  terranix-storage,
  self,
}:
let
  system = "x86_64-linux";
  tofu = import ../packages/opentofu.nix { inherit pkgs; };

  nixosTerraformConfigs =
    (nixpkgs.lib.attrsets.foldlAttrs (acc: name: value: {
      terranixM = (nixpkgs.lib.attrsets.recursiveUpdate acc.terranixM (value.config.terranix or { }));
    }) { terranixM = { }; } self.nixosConfigurations).terranixM;

  terraformConfiguration = terranix.lib.terranixConfiguration {
    inherit system;
    modules = [
      nixosTerraformConfigs
      terranix-storage
    ];
  };

in
{
  init = {
    type = "app";
    program = toString (
      pkgs.writers.writeBash "init" ''
        if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
        cp ${terraformConfiguration} config.tf.json
        ${tofu}/bin/tofu init
        # rm -f config.tf.json
      ''
    );
  };

  apply = {
    type = "app";
    program = toString (
      pkgs.writers.writeBash "apply" ''
        if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
        cp ${terraformConfiguration} config.tf.json
        ${tofu}/bin/tofu apply
        # rm -f config.tf.json
      ''
    );
  };

  plan = {
    type = "app";
    program = toString (
      pkgs.writers.writeBash "plan" ''
        if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
        cp ${terraformConfiguration} config.tf.json
        ${tofu}/bin/tofu init
        ${tofu}/bin/tofu plan
        # rm -f config.tf.json
      ''
    );
  };

  import = {
    type = "app";
    program = toString (
      pkgs.writers.writeBash "import" ''
        if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
        cp ${terraformConfiguration} config.tf.json
        ${
          # Import all nixos configurations in case they already exist
          builtins.concatStringsSep "\n" (
            builtins.map (name: ''
              ${tofu}/bin/tofu import incus_instance.${name} ${name},image=${
                nixosTerraformConfigs.resource.incus_instance.${name}.image
              }
            '') (builtins.attrNames nixosTerraformConfigs.resource.incus_instance)
          )
        }

        ${builtins.concatStringsSep "\n" (
          builtins.map (name: ''
            ${tofu}/bin/tofu import incus_storage_pool.${name} ${
              terranix-storage.resource.incus_storage_pool.${name}.name
            }
          '') (builtins.attrNames terranix-storage.resource.incus_storage_pool)
        )}

        ${builtins.concatStringsSep "\n" (
          builtins.map (name: ''
            ${tofu}/bin/tofu import incus_storage_volume.${name} /${
              terranix-storage.resource.incus_storage_volume.${name}.pool
            }/${terranix-storage.resource.incus_storage_volume.${name}.name}
          '') (builtins.attrNames terranix-storage.resource.incus_storage_volume)
        )}

        ${builtins.concatStringsSep "\n" (
          builtins.map (name: ''
            ${tofu}/bin/tofu import incus_network_forward.${name} /${
              nixosTerraformConfigs.resource.incus_network_forward.${name}.network
            }/${nixosTerraformConfigs.resource.incus_network_forward.${name}.listen_address}
          '') (builtins.attrNames nixosTerraformConfigs.resource.incus_network_forward)
        )}
        # rm -f config.tf.json
      ''
    );
  };

  destroy = {
    type = "app";
    program = toString (
      pkgs.writers.writeBash "destroy" ''
        if [[ -e config.tf.json ]]; then rm -f config.tf.json; fi
        cp ${terraformConfiguration} config.tf.json
        ${tofu}/bin/terraform destroy
        rm -f config.tf.json
      ''
    );
  };
}
