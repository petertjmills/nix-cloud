{
  pkgs,
  config,
  inputs,
  ...
}:
let
  url = "pm4.uk";
in
{
  imports = [
    inputs.sops-nix.nixosModules.sops
    ../options/headscale.nix
    ../modules/dns.nix
  ];

  ip = "167.235.63.14";

  boot.kernel.sysctl = {
    "net.ipv4.ip_forward" = 1;
  };

  sops.age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  sops.age.generateKey = true;
  sops.secrets.cloudflare_api_key = {
    sopsFile = "${inputs.secrets}/cloudflare_api/pm4.uk.enc";
    format = "binary";
  };
  sops.secrets.headscale_sky = {
    sopsFile = "${inputs.secrets}/headscale/sky";
    format = "binary";
    owner = config.services.headscale.user;
  };
  sops.secrets.headscale_cirrus = {
    sopsFile = "${inputs.secrets}/headscale/cirrus";
    format = "binary";
    owner = config.services.headscale.user;
  };
  sops.secrets.headscale_peter = {
    sopsFile = "${inputs.secrets}/headscale/peter";
    format = "binary";
    owner = config.services.headscale.user;
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "cirrus_pm4_cert@pm4.uk";
    certs."wildcard.pm4.uk" = {
      credentialFiles."CF_DNS_API_TOKEN_FILE" = config.sops.secrets.cloudflare_api_key.path;
      dnsProvider = "cloudflare";
      domain = "*.${url}";
    };
  };

  users.users."${config.services.headscale.user}".extraGroups = [
    "${config.security.acme.defaults.group}"
  ];

  networking.hostName = "cirrus";

  environment.defaultPackages = [
    pkgs.headscale
  ];

  services.tailscale = {
    enable = true;
    useRoutingFeatures = "both";
    authKeyFile = config.sops.secrets.headscale_cirrus.path;
    extraUpFlags = [
      "--advertise-exit-node"
      "--login-server=https://hs.${url}"
    ];
    port = 49999;
    openFirewall = true;
  };

  services.headscale = {
    enable = true;
    address = "0.0.0.0";
    port = 443;

    use-declarative-users = true;
    users = [
      {
        id = 1;
        name = "cirrus";
        keys = [
          {
            ephemeral = false;
            path = config.sops.secrets.headscale_cirrus.path;
          }
        ];
      }
      {
        id = 2;
        name = "sky";
        keys = [
          {
            ephemeral = false;
            path = config.sops.secrets.headscale_sky.path;
          }
        ];
      }
      {
        id = 3;
        name = "peter";
        keys = [
          {
            ephemeral = false;
            path = config.sops.secrets.headscale_peter.path;
          }
        ];
      }
    ];

    settings = {
      server_url = "https://hs.${url}";
      listen_addr = "0.0.0.0:443";
      metrics_listen_addr = "127.0.0.1:9090";
      grpc_listen_addr = "127.0.0.1:50443";
      noise.private_key_path = "/var/lib/headscale/noise_private.key";

      prefixes = {
        v4 = "100.64.0.0/10";
        v6 = "fd7a:115c:a1e0::/48";
        allocation = "sequential";
      };

      derp.server = {
        enabled = false;
        region_id = 999;
        stun_listen_addr = "0.0.0.0:3478";
        auto_update_enabled = true;
        automatically_add_embedded_derp_region = true;
      };

      disable_check_updates = true;

      database = {
        type = "sqlite";
        sqlite.path = "/var/lib/headscale/db.sqlite";
      };

      tls_cert_path = "${config.security.acme.certs."wildcard.pm4.uk".directory}/cert.pem";
      tls_key_path = "${config.security.acme.certs."wildcard.pm4.uk".directory}/key.pem";

      dns = {
        magic_dns = true;
        base_domain = "ts.pm4.uk";
        override_local_dns = false;
        nameservers.global = [
          "127.0.0.1" # Redirect all DNS queries to unbound, set below
          "100.64.0.3" # This should be set to the cirrus ip. I don't know how to automate this. This is why headscale sucks
        ];
      };

      unix_socket_permission = "0770";
    };

  };

  local.dns.server = true;
  local.dns.records = [
    {
      name = "test.metachroma.co.";
      type = "A";
      data = "10.0.0.2";
    }
    {
      name = "test.metachroma.co.";
      type = "MX";
      data = "10 test.metachroma.co.";
    }
    {
      name = "_dmarc.metachroma.co.";
      type = "TXT";
      data = "v=DMARC1;p=reject;rua=mailto:dmarc@metachroma.co";
    }
    {
      name = "test.metachroma.co.";
      type = "TXT";
      data = "v=spf1 ip4:193.237.206.90 ~all";
    }
  ];

  networking.firewall = {
    allowedTCPPorts = [
      443
    ];
    allowedUDPPorts = [

    ];
  };
}
