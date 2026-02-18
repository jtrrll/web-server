{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      server.services.faktory = {
        enable = true;
        image = config.packages.faktoryDockerImage;
      };
      packages.faktoryDockerImage = pkgs.callPackage (
        { dockerTools }:
        dockerTools.pullImage {
          imageName = "contribsys/faktory";
          finalImageTag = "1.9.3";
          os = "linux";
          arch = "amd64";
          imageDigest = "sha256:ccaa5df6a445ee678a7a95822e32e3cc8a5d41d70ebda75b82111d4e678c249c";
          sha256 = "sha256-jujSjxVH67SF+h9cBy8AUysBtYnUfiQyoyn4tkYHLMA=";
        }
      ) { };
    };
}
