{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      server.services.grafana = {
        enable = true;
        image = config.packages.grafanaDockerImage;
      };
      packages.grafanaDockerImage = pkgs.callPackage (
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
    };
}
