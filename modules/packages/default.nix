{ inputs, ... }:
{
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
      packages = {
        caddyDockerImage = callPackage ./caddy_docker_image.nix {
          faktoryPort = config.packages.faktoryDockerImage.ports.ui;
          grafanaPort = config.packages.grafanaDockerImage.ports.server;
          portfolioPort = config.packages.portfolioDockerImage.ports.server;
          ttydPort = config.packages.ttydDockerImage.ports.server;
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
