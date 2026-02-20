{ inputs, self, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  flake.modules.server.telemetry =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.telemetry;
    in
    {
      options.telemetry.enable = lib.mkEnableOption "telemetry services";
      config = lib.mkIf cfg.enable {
        services.telemetry.image = self.packages.${pkgs.stdenv.system}.otelLGTMDockerImage;
      };
    };

  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages.otelLGTMDockerImage = pkgs.callPackage (
        {
          dockerTools,
        }:
        dockerTools.pullImage {
          imageName = "grafana/otel-lgtm";
          finalImageTag = "0.18.1";
          os = "linux";
          arch = "amd64";
          imageDigest = "sha256:c97e42ac04e8855bf24f8c989082edfdccd49e57719af9814dadaebc2b5aaeab";
          sha256 = "sha256-Mf+bdT9IYe28RVLbwNqQe7iJhIjx71NBt105zUEMjN8=";
        }
      ) { };
    };
}
