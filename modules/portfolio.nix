{
  perSystem =
    {
      inputs',
      pkgs,
      ...
    }:
    {
      packages.portfolioDockerImage =
        pkgs.callPackage
          (
            {
              buildEnv,
              dockerTools,
              port,
              portfolio,
            }:
            (dockerTools.buildImage {
              name = portfolio.pname;
              tag = portfolio.version;

              copyToRoot = buildEnv {
                name = "image-root";
                paths = [
                  portfolio
                ];
                pathsToLink = [ "/bin" ];
              };
              config = {
                Cmd = [
                  "/bin/server"
                  "--port"
                  "${toString port}"
                ];
                ExposedPorts = {
                  "${toString port}/tcp" = { };
                };
              };
            }).overrideAttrs
              {
                meta.description = "A Docker image that provides a server for Jackson Terrill's personal portfolio";
                passthru.ports = {
                  server = port;
                };
              }
          )
          {
            port = 8080;
            portfolio = inputs'.portfolio.packages.default;
          };
    };
}
