{
  inputs,
  self,
  ...
}:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  perSystem =
    { config, pkgs, ... }:
    {
      packages = {
        defaultServer = pkgs.callPackage (
          {
            domain,
          }:
          self.lib.mkServer {
            inherit pkgs;
            modules = [
              {
                reverseProxy = {
                  enable = true;
                  caddyfile = ''
                    {
                      ${
                        if domain == "localhost" then
                          ''
                            admin :2019 {
                              origins admin.localhost
                            }
                            local_certs
                          ''
                        else
                          "admin off"
                      }
                    }

                    www.${domain} {
                      handle {
                        reverse_proxy portfolio:8080
                      }
                    }

                    admin.${domain} {
                      basic_auth {
                        {$ADMIN_USERNAME} {$ADMIN_PASSWORD_HASHED}
                      }

                      ${
                        if domain == "localhost" then
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

                      handle /faktory* {
                        reverse_proxy faktory:7420 {
                          header_up X-Script-Name /faktory
                        }
                      }

                      handle /grafana* {
                        reverse_proxy grafana:3000 {
                          header_up X-WEBAUTH-USER {http.auth.user}
                        }
                      }

                      handle {
                        respond "404 Not Found" 404
                      }
                    }

                    *.${domain} {
                      redir https://www.${domain}{uri}
                    }
                  '';
                };
                services.caddy.environment = {
                  ADMIN_USERNAME = "\${ADMIN_USERNAME}";
                  ADMIN_PASSWORD_HASHED = "\${ADMIN_PASSWORD_HASHED}";
                };

                jobs.enable = true;

                telemetry.enable = true;
                services = {
                  grafana.environment = {
                    GF_AUTH_PROXY_ENABLED = true;
                    GF_SERVER_ROOT_URL = "/grafana";
                    GF_SERVER_SERVE_FROM_SUB_PATH = true;
                  };
                  portfolio.environment = {
                    OTEL_EXPORTER_OTLP_ENDPOINT = "http://otelCollector:4318";
                    OTEL_EXPORTER_OTLP_PROTOCOL = "http/protobuf";
                  };
                };

                portfolio.enable = true;
              }
            ];
          }
        ) { domain = "jtrrll.com"; };
        devServer = config.packages.defaultServer.override { domain = "localhost"; };
      };
    };
}
