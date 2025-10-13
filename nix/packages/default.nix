{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = rec {
        caddyDockerImage = pkgs.callPackage ./caddy_docker_image.nix { };
        dockerCompose = pkgs.callPackage ./docker_compose.nix {
          inherit caddyDockerImage;
          serviceDockerImages = {
            grafana = grafanaDockerImage;
            jaeger = jaegerDockerImage;
            loki = lokiDockerImage;
            portfolio = portfolioDockerImage;
            prometheus = prometheusDockerImage;
          };
        };
        grafanaDockerImage = pkgs.callPackage ./grafana_docker_image.nix { };
        jaegerDockerImage = pkgs.callPackage ./jaeger_docker_image.nix { };
        lokiDockerImage = pkgs.callPackage ./loki_docker_image.nix { };
        portfolioDockerImage = pkgs.callPackage ./portfolio_docker_image.nix {
          portfolio = inputs.portfolio.packages."x86_64-linux".default;
        };
        prometheusDockerImage = pkgs.callPackage ./prometheus_docker_image.nix { };
      };
    };
}
