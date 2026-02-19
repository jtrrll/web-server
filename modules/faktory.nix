{ inputs, self, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  flake.modules.server.faktory =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.faktory;
    in
    {
      options.faktory.enable = lib.mkEnableOption "a faktory service";
      config = lib.mkIf cfg.enable {
        services.faktory.image = self.packages.${pkgs.stdenv.system}.faktoryDockerImage;
      };
    };

  perSystem =
    {
      pkgs,
      ...
    }:
    {
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
