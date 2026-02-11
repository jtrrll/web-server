{
  perSystem =
    { pkgs, ... }:
    {
      packages = rec {
        grafanaDockerImage = pkgs.callPackage ./grafana.nix {
          lokiPort = lokiDockerImage.ports.server;
          mimirPort = mimirDockerImage.ports.server;
          tempoPort = tempoDockerImage.ports.server;
        };
        lokiDockerImage = pkgs.callPackage ./loki.nix { };
        mimirDockerImage = pkgs.callPackage ./mimir.nix { };
        otelCollectorDockerImage = pkgs.callPackage ./otel_collector.nix {
          lokiPort = lokiDockerImage.ports.server;
          mimirPort = mimirDockerImage.ports.server;
          tempoPort = tempoDockerImage.ports.server;
        };
        tempoDockerImage = pkgs.callPackage ./tempo.nix { };
      };
    };
}
