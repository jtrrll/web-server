{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages.postgresqlDockerImage =
        pkgs.callPackage
          (
            {
              dockerTools,
            }:
            let
              baseImage = dockerTools.pullImage {
                imageName = "postgres";
                finalImageTag = "18.1";
                os = "linux";
                arch = "amd64";
                imageDigest = "sha256:1090bc3a8ccfb0b55f78a494d76f8d603434f7e4553543d6e807bc7bd6bbd17f";
                sha256 = "sha256-/uzjggR+DIImFPcyUSK1m4M/xcFYnQDTiu2KD9RZiME=";
              };
            in
            baseImage.overrideAttrs {
              meta.description = "A Docker image that provides a PostgreSQL database server";
            }
          )
          {
          };
    };
}
