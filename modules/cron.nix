{ inputs, self, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  flake.modules.server.cron =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.cron;
    in
    {
      options.cron.enable = lib.mkEnableOption "a cron service";
      config = lib.mkIf cfg.enable {
        services.cron.image = self.packages.${pkgs.stdenv.system}.cronDockerImage;
      };
    };

  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages.cronDockerImage = pkgs.callPackage (
        {
          busybox,
          dockerTools,
          runCommand,
          writeTextFile,
        }:
        let
          crontab = writeTextFile {
            name = "crontab";
            text = ''
              # Add cron jobs here
              # Example: */5 * * * * /usr/local/bin/example-job.sh
            '';
          };
        in
        dockerTools.buildLayeredImage {
          name = "cron";
          tag = "latest";
          architecture = "amd64";

          contents = [
            busybox
            (runCommand "crontab" { } ''
              mkdir -p $out/etc/crontabs
              cp ${crontab} $out/etc/crontabs/root
            '')
          ];
          config.Cmd = [
            "/bin/crond"
            "-f"
            "-l"
            "2"
          ];
        }
      ) { inherit (inputs.nixpkgs.legacyPackages.x86_64-linux) busybox; };
    };
}
