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

                    ${domain} {
                      redir https://www.${domain}{uri}
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
                  '';
                };
                services.caddy.environment = {
                  ADMIN_USERNAME = "\${ADMIN_USERNAME}";
                  ADMIN_PASSWORD_HASHED = "\${ADMIN_PASSWORD_HASHED}";
                };
                telemetry.enable = true;
                faktory.enable = true;

                portfolio.enable = true;
              }
            ];
          }
        ) { domain = "jtrrll.com"; };
        devServer = config.packages.defaultServer.override { domain = "localhost"; };
      };
    };
}
