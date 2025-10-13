{
  buildEnv,
  dockerTools,
  runCommand,
  writeTextFile,
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
              reverse_proxy portfolio:8080
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
              reverse_proxy grafana:3000 {
                header_up X-WEBAUTH-USER {http.auth.user}
              }
            }

            handle /jaeger* {
              reverse_proxy jaeger:16686
            }

            handle /prometheus* {
              reverse_proxy prometheus:9090
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
