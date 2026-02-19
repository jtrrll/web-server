{ inputs, self, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  flake.modules.server.portfolio =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      cfg = config.portfolio;
    in
    {
      options.portfolio.enable = lib.mkEnableOption "a portfolio service";
      config = lib.mkIf cfg.enable {
        services.portfolio.image = self.packages.${pkgs.stdenv.system}.portfolioDockerImage;
      };
    };

  perSystem =
    {
      pkgs,
      ...
    }:
    {
      packages.portfolioDockerImage =
        pkgs.callPackage
          (
            {
              dockerTools,
              portfolio,
            }:
            (dockerTools.buildLayeredImage {
              name = portfolio.pname;
              tag = portfolio.version;
              architecture = "amd64";
              contents = [ portfolio ];
              config = {
                Cmd = [ "/bin/server" ];
                ExposedPorts."8080/tcp" = { };
                User = "65534";
              };
            }).overrideAttrs
              {
                meta.description = "A Docker image that provides a server for Jackson Terrill's personal portfolio";
              }
          )
          {
            portfolio = inputs.portfolio.packages.x86_64-linux.default;
          };
    };
}
