{ inputs, self, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  flake.modules.server.reverseProxy =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.reverseProxy;
    in
    {
      options.reverseProxy = {
        enable = lib.mkEnableOption "a reverse proxy service";
        caddyfile = lib.mkOption {
          type = lib.types.str;
          description = "The content of the Caddyfile configuration";
        };
      };

      config = lib.mkIf cfg.enable {
        services.caddy = {
          image = self.packages.${pkgs.stdenv.system}.caddyDockerImage;
          ports = [
            "80:80"
            "443:443"
          ];
          volumes = [
            "${
              self.packages.${pkgs.stdenv.system}.caddyfile.override { text = cfg.caddyfile; }
            }:/etc/caddy/Caddyfile:ro"
            "caddy_config:/config"
            "caddy_data:/data"
          ];
        };
        volumes = {
          "caddy_config" = { };
          "caddy_data" = { };
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
        caddyfile = pkgs.callPackage (
          {
            text,
            writeTextFile,
          }:
          writeTextFile {
            name = "Caddyfile";
            inherit text;
          }
        ) { };
        caddyDockerImage = pkgs.callPackage (
          {
            dockerTools,
          }:
          dockerTools.pullImage {
            imageName = "caddy";
            finalImageTag = "latest";
            os = "linux";
            arch = "amd64";
            imageDigest = "sha256:d8c17a862962def15cde69863a3a463f25a2664942eafd7bdbf050e9c3116b83";
            sha256 = "sha256-7bF1+AfCVhW399sl6vKLG0/oOmT4a85p0QQQ4jPET58=";
          }
        ) { };
      };
    };
}
