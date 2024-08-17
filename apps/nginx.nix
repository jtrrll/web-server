{
  constants,
  pkgs,
  ...
}: {
  apps."nginx" = let
    config = builtins.toFile "nginx.conf" ''
      daemon off;
      events {
        worker_connections 1024;
      }
      worker_processes auto;

      http {
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;

        server {
          listen 80;
          server_name web-server;

          location /portfolio/ {
            rewrite ^/portfolio/(.*)$ /$1 break;
            proxy_pass http://localhost:${builtins.toString constants.PORTS.PORTFOLIO};
          }

          location / {
            rewrite ^/(.*)$ /portfolio/$1 last;
          }
        }
      }
    '';
    wrapper = pkgs.writeShellScript "nginx" ''
      if [ "$EUID" -ne 0 ]; then
        printf "\033[31;1merror:\033[0m nginx must run as root\n"
        exit 1
      fi
      if [ ! -d "/var/log/nginx" ]; then
        rm -rf "/var/log/nginx/"
        mkdir -p "/var/log/nginx"
      fi
      printf "Running nginx...\n"
      ${pkgs.nginx}/bin/nginx -c ${config}
      printf "\n"
    '';
  in {
    type = "app";
    program = "${wrapper}";
  };
}
