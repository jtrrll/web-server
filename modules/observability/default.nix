{
  perSystem =
    { lib, pkgs, ... }:
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
        grafanaDockerImage = callPackage ./grafana_docker_image.nix {
          lokiPort = lokiDockerImage.ports.server;
          mimirPort = mimirDockerImage.ports.server;
          tempoPort = tempoDockerImage.ports.server;
        };
        lokiDockerImage = callPackage ./loki_docker_image.nix { };
        mimirDockerImage = callPackage ./mimir_docker_image.nix { };
        otelCollectorDockerImage = callPackage ./otel_collector_docker_image.nix {
          lokiPort = lokiDockerImage.ports.server;
          mimirPort = mimirDockerImage.ports.server;
          tempoPort = tempoDockerImage.ports.server;
        };
        tempoDockerImage = callPackage ./tempo_docker_image.nix { };
      };
    };
}
