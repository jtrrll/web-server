{ inputs, self, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  flake.modules.server.jobs =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.jobs;
    in
    {
      options.jobs.enable = lib.mkEnableOption "asynchronous job services";
      config = lib.mkIf cfg.enable {
        services = {
          cron.image = self.packages.${pkgs.stdenv.system}.cronDockerImage;
          faktory.image = self.packages.${pkgs.stdenv.system}.faktoryDockerImage;
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
        crontab =
          pkgs.callPackage
            (
              { text, writeTextFile }:
              writeTextFile {
                name = "crontab";
                inherit text;
              }
            )
            {
              text = ''
                # Add cron jobs here
                # Example: */5 * * * * /usr/local/bin/example-job.sh
              '';
            };
        cronDockerImage =
          pkgs.callPackage
            (
              {
                busybox,
                crontab,
                dockerTools,
                runCommand,
              }:
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
            )
            {
              inherit (inputs.nixpkgs.legacyPackages.x86_64-linux) busybox;
              inherit (self.packages.${pkgs.stdenv.system}) crontab;
            };
        faktoryDockerImage = pkgs.callPackage (
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
    };
}
