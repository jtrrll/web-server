{
  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages.minecraftServerDockerImage = pkgs.callPackage (
        { dockerTools }:
        let
          baseImage = dockerTools.pullImage {
            imageName = "itzg/minecraft-server";
            finalImageTag = "java25";
            os = "linux";
            arch = "amd64";
            imageDigest = "sha256:14f20e2e6a48b50149c938670b11777371c5f162dde4224465c6377ab8e3db01";
            sha256 = "sha256-F1VgUqpZFTg7EQvUJXnnNjYWBYiUatw3orum/aNboxo=";
          };
        in
        baseImage.overrideAttrs {
          meta.description = "A Docker image that provides a Minecraft server with dynamic versions, server types, and modpack support";
        }
      ) { };
    };
}
