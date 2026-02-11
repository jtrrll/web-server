{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      packages.caddyDockerImage =
        pkgs.callPackage
          (
            {
              buildEnv,
              dockerTools,
              runCommand,
              writeTextFile,
              faktoryPort,
              grafanaPort,
              portfolioPort,
              ttydPort,
            }:
            let
              baseImage = dockerTools.pullImage {
                imageName = "caddy";
                imageDigest = "sha256:614bbc6da7ec42f3c76077e86f429297047680f9cb420ad0f07a8fe049193d89";
                sha256 = "sha256-w2dNPIEQUltUSn/CfcPGxKib7fOYwKwH3LiAE2dfM1U=";
              };
              mkCaddyImage =
                {
                  dev ? false,
                }:
                let
                  caddyfile = writeTextFile {
                    name = "Caddyfile";
                    text = ''
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
                        handle {
                          reverse_proxy portfolio:${toString portfolioPort}
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
                              }''
                          else
                            ""
                        }

                        basicauth {
                          {$ADMIN_USERNAME} {$ADMIN_PASSWORD_HASHED}
                        }

                        handle /grafana* {
                          reverse_proxy grafana:${toString grafanaPort} {
                            header_up X-WEBAUTH-USER {http.auth.user}
                          }
                        }

                        handle /faktory* {
                          reverse_proxy faktory:${toString faktoryPort} {
                            header_up X-Script-Name /faktory
                          }
                        }

                        handle_path /terminal/* {
                          reverse_proxy ttyd:${toString ttydPort}
                        }

                        handle {
                          respond "404 Not Found" 404
                        }
                      }
                    '';
                  };
                  domain = if dev then "localhost" else "jtrrll.com";
                in
                (dockerTools.buildImage {
                  name = "web-server-caddy";
                  tag = "latest";
                  fromImage = baseImage;

                  copyToRoot = buildEnv {
                    name = "image-root";
                    paths = [
                      (runCommand "caddyfile" { } ''
                        mkdir -p $out/etc/caddy
                        cp ${caddyfile} $out/etc/caddy/Caddyfile
                      '')
                    ];
                  };
                  config = {
                    Cmd = [
                      "caddy"
                      "run"
                      "--config"
                      "/etc/caddy/Caddyfile"
                    ];
                    ExposedPorts = {
                      "80/tcp" = { };
                      "443/tcp" = { };
                    };
                  };
                }).overrideAttrs
                  {
                    passthru.ports = {
                      HTTP = 80;
                      HTTPS = 443;
                    };
                  };
            in
            (mkCaddyImage { }).overrideAttrs (prev: {
              passthru = prev.passthru // {
                dev = mkCaddyImage { dev = true; };
              };
            })
          )
          {
            faktoryPort = config.packages.faktoryDockerImage.ports.ui;
            grafanaPort = config.packages.grafanaDockerImage.ports.server;
            portfolioPort = config.packages.portfolioDockerImage.ports.server;
            ttydPort = config.packages.ttydDockerImage.ports.server;
          };
    };
}
