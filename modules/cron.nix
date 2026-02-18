{ inputs, ... }:
{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      server.services.cron = {
        image = config.packages.cronDockerImage;
      };
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
