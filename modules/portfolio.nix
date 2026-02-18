{ inputs, ... }:
{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      server.services.portfolio = {
        enable = true;
        image = config.packages.portfolioDockerImage;
      };
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
