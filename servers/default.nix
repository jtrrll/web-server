{ config, inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  perSystem =
    { pkgs, ... }:
    {
      packages.default = config.flake.lib.mkServer {
        inherit pkgs;
        modules = [
          {
            reverseProxy = {
              enable = true;
              caddyfile = ''
                {
                  admin off
                }

                jtrrll.com {
                  redir https://www.jtrrll.com{uri}
                }

                www.jtrrll.com {
                }

                admin.jtrrll.com {
                  basicauth {
                    {$ADMIN_USERNAME} {$ADMIN_PASSWORD_HASHED}
                  }

                  handle /grafana* {
                    reverse_proxy grafana:3000 {
                      header_up X-WEBAUTH-USER {http.auth.user}
                    }
                  }

                  handle /faktory* {
                    reverse_proxy faktory:7420 {
                      header_up X-Script-Name /faktory
                    }
                  }

                  handle {
                    respond "404 Not Found" 404
                  }
                }
              '';
            };
            telemetry.enable = true;
            faktory.enable = true;

            portfolio.enable = true;
          }
        ];
      };
    };
}
