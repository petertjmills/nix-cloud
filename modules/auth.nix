{
  pkgs,
  modulesPath,
  inputs,
  unstable,
  ...
}:
{
  virtualisation.forwardPorts = [
    {
      from = "host";
      host.port = 8080;
      guest.port = 8080;
    }
    {
      from = "host";
      host.port = 443;
      guest.port = 443;
    }
    {
      from = "host";
      host.port = 5432;
      guest.port = 5432;
    }
  ];

  networking.firewall.allowedTCPPorts = [
    8080
    443
    5432
  ];

  services.nginx.enable = true;
  services.nginx.virtualHosts."localhost" = {
    # enableACME = true;
    forceSSL = true;
    sslCertificate = "/etc/zitadel/selfsigned.crt";
    sslCertificateKey = "/etc/zitadel/selfsigned.key";
    locations."/" = {
      proxyPass = "http://127.0.0.1:8080";
      extraConfig = ''
        grpc_pass grpc://127.0.0.1:8080;
        grpc_set_header Host $host:$server_port;
        grpc_set_header X-Forwarded-Proto https;
      '';
    };
  };

  services.postgresql = {
    enable = true;
    package = pkgs.postgresql_17;
    enableTCPIP = true;
    settings.port = 5432;
    authentication = pkgs.lib.mkOverride 10 ''
      #...
      #type database DBuser origin-address auth-method
      # ipv4
      local all all              trust
      host  all      all     127.0.0.1/32   trust
      host all       all     ::1/128        trust
      host  all      all     all  trust
      # ipv6
    '';
    ensureDatabases = [ "zitadel" ];
    ensureUsers = [
      {
        name = "zitadel";
        ensureDBOwnership = true;
        ensureClauses.login = true;
        ensureClauses.superuser = true;
      }
    ];
  };
  services.zitadel = {
    enable = true;
    masterKeyFile = "/etc/zitadel/masterKey";

    settings = {
      ExternalDomain = "localhost";
      ExternalPort = 443;
      ExternalSecure = true;
      TLS.Enabled = false;

      Database.postgres = {
        Host = "/var/run/postgresql/";
        Port = 5432;
        Database = "zitadel";
        Admin = {
          Username = "zitadel";
          SSL.Mode = "disable";
          ExistingDatabase = "zitadel";
        };
        User = {
          Username = "zitadel";
          SSL.Mode = "disable";
        };
      };
    };
    steps.FirstInstance = {
      MachineKeyPath = "/etc/zitadel/machineKey";
      PatPath = "/etc/zitadel/pat";
      InstanceName = "pm4 Auth";
      Org = {
        Name = "pm4";
        Human = {
          UserName = "admin";
          FirstName = "admin";
          LastName = "admin";
          Email.Verified = true;
          Password = "Password1!";
          PasswordChangeRequired = true;
        };
      };
      LoginPolicy.AllowRegister = false;
    };
  };

  environment.etc."zitadel/masterKey" = {
    text = "MasterkeyNeedsToHave32Characters";
  };

  environment.etc."zitadel/selfsigned.crt" = {
    text = ''
      -----BEGIN CERTIFICATE-----
      MIIC0jCCAboCCQCO8nJ9ih4azTANBgkqhkiG9w0BAQsFADArMRIwEAYDVQQDDAls
      b2NhbGhvc3QxFTATBgNVBAoMDFppdGFkZWwgRGVtbzAeFw0yNjAxMDMwMTMwMTNa
      Fw0yNjAyMDIwMTMwMTNaMCsxEjAQBgNVBAMMCWxvY2FsaG9zdDEVMBMGA1UECgwM
      Wml0YWRlbCBEZW1vMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAxNP2
      qRJqVJm//bHVyqUWU4JOB8FHtdZxIxYfFIrSywNrR88lp1EoD3guGXlmJJRDzo0y
      wLjnx7wq+baQddd5RS8CSK6XbC8xzCj9F88fJ11i8ks3UPcSFKU3wu00EY6erWrc
      HU+aXC5LqMtKb4Dc4b2fbObAYoxr9/uXk5OGnSMHbU7fxFFc4wY2XDz03YjoCyls
      xjpqQMIRnvuhWj4B6ztz3yFtyeFOiRkf+ZxXjJMTu0mwR06t9IL2MwEGvyu8Xiz4
      HWaGL2p7TVbkABZxidmiJPgUoByWhjEoCYC5+4nmCoOdmLtK2ktWG7KEFKyKYgTq
      y3Hhx4ops9BVhS0aBwIDAQABMA0GCSqGSIb3DQEBCwUAA4IBAQBX2m94ezB1RME5
      i2KSoKfMjyWST77+cXty/mTO2QJqz4ASTmbel3dVo00So+mkPcwUu9nHt0xZuPeD
      Lq51V7+lN44i+MbnJ50tWPi9fD2AOrnofBU22PIpzLnbC6zE8a9JJBTVRKqQms7p
      HbhsMlKliul3Hscc1rBTsyS3+VmeBdnb6PTbPEzcYqQJPK/g/DdBCc54C+XK70I+
      rSFAGl3u1DsN5jWB/3qFy3tKvsoJa6PKRolVmU85kwVGJXRhjL+1dN3nFFAl4urK
      J3YxwdsOPtIKDtjrfOhgWlxzn1S6Lp2Mln2TiLpJc9jNWusuSl2f3I7YL5xICkCs
      qQWsCvzG
      -----END CERTIFICATE-----
    '';
  };

  environment.etc."zitadel/selfsigned.key" = {
    text = ''
      -----BEGIN PRIVATE KEY-----
      MIIEvAIBADANBgkqhkiG9w0BAQEFAASCBKYwggSiAgEAAoIBAQDE0/apEmpUmb/9
      sdXKpRZTgk4HwUe11nEjFh8UitLLA2tHzyWnUSgPeC4ZeWYklEPOjTLAuOfHvCr5
      tpB113lFLwJIrpdsLzHMKP0Xzx8nXWLySzdQ9xIUpTfC7TQRjp6tatwdT5pcLkuo
      y0pvgNzhvZ9s5sBijGv3+5eTk4adIwdtTt/EUVzjBjZcPPTdiOgLKWzGOmpAwhGe
      +6FaPgHrO3PfIW3J4U6JGR/5nFeMkxO7SbBHTq30gvYzAQa/K7xeLPgdZoYvantN
      VuQAFnGJ2aIk+BSgHJaGMSgJgLn7ieYKg52Yu0raS1YbsoQUrIpiBOrLceHHiimz
      0FWFLRoHAgMBAAECggEACiUqx5gtZuLt5HOwI1vTBMboormxqou9FSPkwjhNmS05
      8F+a/z7No858AdAiFayWuiTJAuoE+GSYinqAg7Jxi8FaisiFAYyFMpLCSOHiJzNH
      EFoUJdY2Vl4Vu7RiRK1nPGUPp2sc97djKvYfhhPMTs5pU0GplOrL/eI38+FcxOic
      K2qcb+kEe44MCkG4LkIv0QMri8KsicUADdGeuQU/8foP9YFlLBiwF9t1XVQu5cEE
      u/y5YR9CYntDLBWjSEeQO0TIX+YzcT0rBB95lwX5SGgAEwqTBHofXaRDtfvZ5GfS
      BxtwBdurCUi8VcAaEYUY2p/y3DLEmCnbnPhqY/aD0QKBgQDgpaAdihFtdYtOjwNN
      I4qc9RzB0pza1Kbelus/izTEUBd4MnL0LZUdn29kWFhWdJruy8x+K5zObFkc2YRO
      XQZQbp5qBIHd83M1pPmXQiJB6fJm4ZCO48ufyWJJ1yHQK3qZwe05+g3HAlqECnHM
      E43bg7rT4Bt+ldiYzGBF7lIeJQKBgQDgTGXdeG8x7E2d9uzGzMKRxyiqbSg5JVvH
      9jQcfkB9eaSrhv1kIFMmHCtiJQNrMllDUxxkIzmQlYc946gd8Nws0eyOC6m/KeII
      ekARl6PUzlZyWv//EAwp1Yq2Ax1LGb56l+YHXiIA96LKmoqL7S0NxYXYw85eul/j
      JKtfb/wxuwKBgBiHfTg8fzKohxGI5B9kJhqFWSKA0MfEOIRNjlpd5OEarbVeLNck
      sweNBSi7zMmD6fbxId8U/AY+JmzUA3JbDflyWrHQ1C1cC9RrsyUk/4Ca/vDk6Ffx
      36YO40CU0Qhd9wEa/8A44ZA9XYzVZx+VcwPpGllQOzBTRFdK2ahJIYZRAoGAS+nv
      jB6n28izmGQrTTmeHMLAQ7ZAJ986ChqNFpuwbgdOsXM1rb63Ba4BDO2kE5Lt3Thy
      4n19jS7eoBa+HqwXiN/f5U+TOw0M4Hun1YxyOaNAZOHhxM0EoOASW3oAXxuueUWR
      6Cp27cbihRn7DFLQrdmNbIkQ/sSrkXAmxF1diOMCgYAfLLIy273EZBhDB34eRLvc
      ypQzkncYgQNOAbJcjCpBQJbfLFULU4V0vTH0TYjZ5ovxa1kZeiTJE3/6ajEwski0
      YoLT8a+KExV6llpgAbBdYLAf7ajEBraQin0rHSjOf+cbeSJgqPAkBMG2+9GlT385
      ROUZ1KHc73WETkJ1+iD1yA==
      -----END PRIVATE KEY-----
    '';
  };
}
