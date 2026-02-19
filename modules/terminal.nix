{ inputs, self, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  flake.modules.server.terminal =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.terminal;
    in
    {
      options.terminal.enable = lib.mkEnableOption "a terminal service";
      config = lib.mkIf cfg.enable {
        services.terminal = {
          image = self.packages.${pkgs.stdenv.system}.ttydDockerImage;
          volumes = [
            "${self.packages.${pkgs.stdenv.system}.nixConf}:/etc/nix/nix.conf:ro"
          ];
        };
      };
    };

  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages = {
        ttydDockerImage = pkgs.callPackage (
          { dockerTools }:
          dockerTools.pullImage {
            imageName = "tsl0922/ttyd";
            finalImageTag = "latest";
            os = "linux";
            arch = "amd64";
            imageDigest = "sha256:41939c3fd23c65b52a7060691312f37e09c41822d31ddc82b0321e9bbeb636d5";
            sha256 = "sha256-GLY4RPmGz6LP0ogDLqIrBkI1Eowznse2EovlXoEJmIU=";
          }
        ) { };
        nixConf = pkgs.writeTextFile {
          name = "nix.conf";
          text = ''
            experimental-features = flakes nix-command
          '';
        };
      };
    };
}
