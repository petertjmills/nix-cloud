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
  sops.secrets.headscale_metachroma_backend = {
    sopsFile = "${inputs.secrets}/headscale/metachroma-backend";
    format = "binary";
    owner = config.services.headscale.user;
  };
  sops.secrets.headscale_metachroma_web = {
    sopsFile = "${inputs.secrets}/headscale/metachroma-web";
    format = "binary";
    owner = config.services.headscale.user;
  };
  sops.secrets.headscale_alto = {
    sopsFile = "${inputs.secrets}/headscale/alto";
    format = "binary";
    owner = config.services.headscale.user;
  };

  security.acme = {
    acceptTerms = true;
    defaults.email = "cirrus_pm4_cert@pm4.uk";
    defaults.dnsResolver = "1.1.1.1";
    certs."wildcard.pm4.uk" = {
      credentialFiles."CF_DNS_API_TOKEN_FILE" = config.sops.secrets.cloudflare_api_key.path;
      dnsProvider = "cloudflare";
      domain = "*.${url}";
    };
    certs."wildcard.ts.pm4.uk" = {
      credentialFiles."CF_DNS_API_TOKEN_FILE" = config.sops.secrets.cloudflare_api_key.path;
      dnsProvider = "cloudflare";
      domain = "*.ts.${url}";
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
        name = "system";
        keys = [
          {
            ephemeral = false;
            path = config.sops.secrets.headscale_cirrus.path;
          }
          {
            ephemeral = false;
            path = config.sops.secrets.headscale_sky.path;
          }
          {
            ephemeral = false;
            path = config.sops.secrets.headscale_alto.path;
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
      {
        id = 4;
        name = "sophie";
      }
      {
        id = 5;
        name = "firestick";
      }
      {
        id = 6;
        name = "metachroma";
        keys = [
          {
            ephemeral = false;
            path = config.sops.secrets.headscale_metachroma_backend.path;
          }
          {
            ephemeral = false;
            path = config.sops.secrets.headscale_metachroma_web.path;
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
        override_local_dns = true;
        nameservers.global = [
          #"127.0.0.1" # Redirect all DNS queries to unbound, set below. UPDATE commented out as it broke things
          # "https://cirrus.ts.pm4.uk/dns-query"
          # "100.64.0.6" # This should be set to the cirrus ip (this machine). I don't know how to automate this. This is why headscale sucks
          "1.1.1.1"
        ];
        nameservers.split."pm4.uk" = [
          "100.64.0.6"
        ];
        nameservers.split."metachroma.co" = [
          "100.64.0.6"
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
    {
      name = "mail.metachroma.co.";
      type = "CNAME";
      data = "backend.ts.pm4.uk.";
    }
    {
      name = "frigate.pm4.uk";
      type = "CNAME";
      data = "alto.ts.pm4.uk";
    }
    {
      name = "home-assistant.pm4.uk";
      type = "CNAME";
      data = "alto.ts.pm4.uk";
    }
    {
      name = "radicale.pm4.uk";
      type = "CNAME";
      data = "sky.ts.pm4.uk";
    }
    {
      name = "restic.pm4.uk";
      type = "CNAME";
      data = "sky.ts.pm4.uk";
    }
    {
      name = "openwebui.pm4.uk";
      type = "CNAME";
      data = "sky.ts.pm4.uk";
    }
    {
      name = "epg.pm4.uk";
      type = "CNAME";
      data = "web1.ts.pm4.uk";
    }
    {
      name = "auth.coredev.pm4.uk";
      type = "CNAME";
      data = "coredev.ts.pm4.uk";
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
