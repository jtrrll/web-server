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
      config = lib.mkIf cfg.enable (
        lib.mkMerge [
          {
            volumes = {
              loki-data = { };
              mimir-data = { };
              tempo-data = { };
            };

            services = {
              grafana = {
                image = self.packages.${pkgs.stdenv.system}.grafanaDockerImage;
                volumes = [
                  "${./grafana_datasources.yaml}:/etc/grafana/provisioning/datasources/datasources.yaml:ro"
                ];
              };

              loki = {
                image = self.packages.${pkgs.stdenv.system}.lokiDockerImage;
                volumes = [
                  "${./loki_config.yaml}:/etc/loki/config.yaml:ro"
                  "loki-data:/loki"
                ];
                environment.LOKI_CONFIG_FILE = "/etc/loki/config.yaml";
              };

              mimir = {
                image = self.packages.${pkgs.stdenv.system}.mimirDockerImage;
                volumes = [
                  "${./mimir_config.yaml}:/etc/mimir/config.yaml:ro"
                  "mimir-data:/data"
                ];
                environment.MIMIR_CONFIG_FILE = "/etc/mimir/config.yaml";
              };

              otelCollector = {
                image = self.packages.${pkgs.stdenv.system}.otelCollectorDockerImage;
                volumes = [
                  "${./otel_collector_config.yaml}:/etc/otelcol-contrib/config.yaml:ro"
                ];
              };

              tempo = {
                image = self.packages.${pkgs.stdenv.system}.tempoDockerImage;
                volumes = [
                  "${./tempo_config.yaml}:/etc/tempo/config.yaml:ro"
                  "tempo-data:/tmp/tempo"
                ];
                environment.TEMPO_CONFIG_FILE = "/etc/tempo/config.yaml";
              };
            };
          }
          {
            services = lib.mapAttrs (name: service: {
              environment = {
                OTEL_SERVICE_NAME = name;
                OTEL_RESOURCE_ATTRIBUTES = "service.version=${service.image.imageTag},deployment.environment=\${DEPLOYMENT_ENV}";
              };
            }) config.services;
          }
        ]
      );
    };

  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages = {
        grafanaDockerImage = pkgs.callPackage (
          {
            dockerTools,
          }:
          dockerTools.pullImage {
            imageName = "grafana/grafana";
            finalImageTag = "main";
            os = "linux";
            arch = "amd64";
            imageDigest = "sha256:cf6c2fa8b9afc3dea45a012ffb4650891895f8fdbbf60593ef07221d8800c7b4";
            sha256 = "sha256-yo+uJ8/Kk0tQ6/e/WjAK/GFg4rlAaB+ffqVIZBNF20U=";
          }
        ) { };
        lokiDockerImage = pkgs.callPackage (
          {
            dockerTools,
          }:
          dockerTools.pullImage {
            imageName = "grafana/loki";
            finalImageTag = "3.6.5";
            os = "linux";
            arch = "amd64";
            imageDigest = "sha256:146a6add37403d7f74aa17f52a849de9babf24f92890613cacf346e12a969efc";
            sha256 = "sha256-Wk3gOMI3ev2iminSM/UO3Dj8Do2TzMbT2VdX/FJ+1Gg=";
          }
        ) { };
        mimirDockerImage = pkgs.callPackage (
          {
            dockerTools,
          }:
          dockerTools.pullImage {
            imageName = "grafana/mimir";
            finalImageTag = "2.17.5";
            os = "linux";
            arch = "amd64";
            imageDigest = "sha256:0a30b23f18ca58cf038b56caed30a4f9282da1aad9832f3208daf0b5b969f77c";
            sha256 = "sha256-JEQvTrtHk08xFOZ4vhngLBnpI9IUhyUu1vYf0lhjrGA=";
          }
        ) { };
        otelCollectorDockerImage = pkgs.callPackage (
          {
            dockerTools,
          }:
          dockerTools.pullImage {
            imageName = "otel/opentelemetry-collector-contrib";
            finalImageTag = "0.145.0";
            os = "linux";
            arch = "amd64";
            imageDigest = "sha256:ac7ad5529b8cf522aa03792bb6d667a7df7d2c3f3da40b2746c51c113ea28c8c";
            sha256 = "sha256-UheuoS3pVf3tr0Dxp48GKdjOtPinIvJX77yXHyX6k8o=";
          }
        ) { };
        tempoDockerImage = pkgs.callPackage (
          {
            dockerTools,
          }:
          dockerTools.pullImage {
            imageName = "grafana/tempo";
            finalImageTag = "2.10.0";
            os = "linux";
            arch = "amd64";
            imageDigest = "sha256:0b85bc67c5c5fa6bc1f8e58a01bfeb741dff6e1c6be89d2a15be9f7ff975ff30";
            sha256 = "sha256-FWI28Eb+3Q1EB+mUkymQCaT4XZW/PNVEttUsO4t658I=";
          }
        ) { };
      };
    };
}
