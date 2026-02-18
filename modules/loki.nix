{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      server.services.loki = {
        image = config.packages.lokiDockerImage;
      };
      packages.lokiDockerImage = pkgs.callPackage (
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
    };
}
