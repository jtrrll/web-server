{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      server = {
        services.reverseProxy = {
          enable = true;
          image = config.packages.caddyDockerImage;
          ports = [
            "80:80"
            "443:443"
          ];
          volumes = [
            "${config.packages.caddyfile}:/etc/caddy/Caddyfile:ro"
            "caddy_config:/config"
            "caddy_data:/data"
          ];
        };
        volumes = {
          "caddy_config" = { };
          "caddy_data" = { };
        };
      };
      packages = {
        caddyfile = pkgs.callPackage (
          {
            writeTextFile,
            portfolioPort,
            grafanaPort,
            faktoryPort,
            ttydPort,
          }:
          let
            mkCaddyfile =
              {
                dev ? false,
              }:
              writeTextFile {
                name = "Caddyfile";
                text =
                  let
                    domain = if dev then "localhost" else "jtrrll.com";
                  in
                  ''
                    {
                      ${
                        if dev then
                          ''
                            admin :2019 {
                              origins admin.localhost
                            }''
                        else
                          "admin off"
                      }
                      ${if dev then "local_certs" else ""}
                    }

                    www.${domain} {
                      redir https://${domain}{uri}
                    }

                    ${domain} {
                      ${
                        if dev then
                          ''
                            handle {
                              reverse_proxy portfolio:${toString portfolioPort}
                            }
                          ''
                        else
                          ""
                      }
                    }

                    admin.${domain} {
                      ${
                        if dev then
                          ''
                            handle_path /caddy/* {
                              reverse_proxy localhost:2019 {
                                header_down Location "^/" "/caddy/"
                              }
                            }
                          ''
                        else
                          ""
                      }

                      basicauth {
                        {$ADMIN_USERNAME} {$ADMIN_PASSWORD_HASHED}
                      }

                      ${
                        if (config.services ? grafana && config.services.grafana.enable) then
                          ''
                            handle /grafana* {
                              reverse_proxy grafana:${toString grafanaPort} {
                                header_up X-WEBAUTH-USER {http.auth.user}
                              }
                            }
                          ''
                        else
                          ""
                      }

                      ${
                        if (config.services ? faktory && config.services.faktory.enable) then
                          ''
                            handle /faktory* {
                              reverse_proxy faktory:${toString faktoryPort} {
                                header_up X-Script-Name /faktory
                              }
                            }
                          ''
                        else
                          ""
                      }

                      ${
                        if (config.services ? terminal && config.services.terminal.enable) then
                          ''
                            handle_path /terminal/* {
                              reverse_proxy terminal:${toString ttydPort}
                            }
                          ''
                        else
                          ""
                      }

                      handle {
                        respond "404 Not Found" 404
                      }
                    }
                  '';
              };
          in
          (mkCaddyfile { }).overrideAttrs (prev: {
            passthru = prev.passthru // {
              dev = mkCaddyfile { dev = true; };
            };
          })
        ) { };
        caddyDockerImage = pkgs.callPackage (
          {
            dockerTools,
          }:
          dockerTools.pullImage {
            imageName = "caddy";
            finalImageTag = "latest";
            os = "linux";
            arch = "amd64";
            imageDigest = "sha256:d8c17a862962def15cde69863a3a463f25a2664942eafd7bdbf050e9c3116b83";
            sha256 = "sha256-w2dNPIEQUltUSn/CfcPGxKib7fOYwKwH3LiAE2dfM1U=";
          }
        ) { };
      };
    };
}
