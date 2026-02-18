{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      server.services.otelCollector = {
        image = config.packages.otelCollectorDockerImage;
      };
      packages.otelCollectorDockerImage = pkgs.callPackage (
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
    };
}
