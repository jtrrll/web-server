{ inputs, ... }:
{
  imports = [
    ./jobs
    ./observability
  ];
  perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      callPackage = lib.callPackageWith (
        pkgs
        // {
          inherit lib;
          writeYAMLFile = (pkgs.formats.yaml { }).generate;
        }
      );
    in
    {
      packages = rec {
        caddyDockerImage = callPackage ./caddy_docker_image.nix {
          faktoryPort = config.packages.faktoryDockerImage.ports.ui;
          grafanaPort = config.packages.grafanaDockerImage.ports.server;
          portfolioPort = portfolioDockerImage.ports.server;
          ttydPort = ttydDockerImage.ports.server;
        };
        dockerCompose = callPackage ./docker_compose.nix {
          inherit caddyDockerImage;
          serviceDockerImages = {
            cron = config.packages.cronDockerImage;
            faktory = config.packages.faktoryDockerImage;
            grafana = config.packages.grafanaDockerImage;
            loki = config.packages.lokiDockerImage;
            mimir = config.packages.mimirDockerImage;
            otelCollector = config.packages.otelCollectorDockerImage;
            portfolio = portfolioDockerImage;
            postgresql = postgresqlDockerImage;
            tempo = config.packages.tempoDockerImage;
            ttyd = ttydDockerImage;
          };
        };
        portfolioDockerImage = callPackage ./portfolio_docker_image.nix {
          portfolio = inputs.portfolio.packages."x86_64-linux".default;
        };
        postgresqlDockerImage = callPackage ./postgresql_docker_image.nix {
          inherit (inputs.nixpkgs.legacyPackages."x86_64-linux") postgresql;
        };
        ttydDockerImage = callPackage ./ttyd_docker_image.nix { };
      };
    };
}
