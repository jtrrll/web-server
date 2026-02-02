{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      apps.default = {
        type = "app";
        program =
          pkgs.callPackage
            (
              {
                docker,
                dockerCompose,
                lib,
                writeShellApplication,
              }:
              writeShellApplication {
                name = "run-docker-compose";
                runtimeInputs = [ docker ];
                text = ''
                  ${lib.concatMapStringsSep "\n" (img: ''
                    echo "Loading ${img.imageName}:${img.imageTag}..."
                    docker load < ${img}
                  '') dockerCompose.images}
                  echo "Starting Docker Compose..."
                  if [ -f .env ]; then
                    docker compose --file ${dockerCompose} --env-file .env up
                  else
                    echo "Warning: .env file not found in current directory"
                    docker compose --file ${dockerCompose} up
                  fi
                '';
              }
            )
            {
              inherit (config.packages) dockerCompose;
            };
      };
      packages.dockerCompose =
        pkgs.callPackage
          (
            {
              caddyDockerImage,
              formats,
              lib,
              serviceDockerImages ? { },
            }:
            let
              mkService =
                _: dockerImage:
                {
                  image = "${dockerImage.imageName}:${dockerImage.imageTag}";
                }
                // (if dockerImage ? ports then { expose = lib.attrValues dockerImage.ports; } else { });
              services = {
                caddy = {
                  image = "${caddyDockerImage.imageName}:${caddyDockerImage.imageTag}";
                  depends_on = lib.attrNames serviceDockerImages;
                  environment = {
                    ADMIN_USERNAME = "\${ADMIN_USERNAME}";
                    ADMIN_PASSWORD_HASHED = "\${ADMIN_PASSWORD_HASHED}";
                  };
                  ports = [
                    "80:${builtins.toString caddyDockerImage.ports.HTTP}"
                    "443:${builtins.toString caddyDockerImage.ports.HTTPS}"
                  ];
                  volumes = [
                    "caddy_config:/config"
                    "caddy_data:/data"
                  ];
                };
              }
              // lib.mapAttrs mkService serviceDockerImages;
            in
            ((formats.yaml { }).generate "docker_compose.yaml" {
              inherit services;
              volumes = {
                "caddy_config" = { };
                "caddy_data" = { };
              };
            }).overrideAttrs
              {
                passthru.images = [ caddyDockerImage ] ++ lib.attrValues serviceDockerImages;
              }
          )
          {
            inherit (config.packages) caddyDockerImage;
            serviceDockerImages = {
              cron = config.packages.cronDockerImage;
              faktory = config.packages.faktoryDockerImage;
              grafana = config.packages.grafanaDockerImage;
              loki = config.packages.lokiDockerImage;
              mimir = config.packages.mimirDockerImage;
              otelCollector = config.packages.otelCollectorDockerImage;
              portfolio = config.packages.portfolioDockerImage;
              postgresql = config.packages.postgresqlDockerImage;
              tempo = config.packages.tempoDockerImage;
              ttyd = config.packages.ttydDockerImage;
            };
          };
    };
}
