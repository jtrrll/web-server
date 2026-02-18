{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      server.services.mimir = {
        image = config.packages.mimirDockerImage;
      };
      packages.mimirDockerImage = pkgs.callPackage (
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
    };
}
