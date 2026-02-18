{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      server.services.tempo = {
        image = config.packages.tempoDockerImage;
      };
      packages.tempoDockerImage = pkgs.callPackage (
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
}
