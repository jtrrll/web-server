{ config, inputs, ... }:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  perSystem =
    { pkgs, ... }:
    {
      packages.default = config.flake.lib.mkServer {
        inherit pkgs;
        modules = [
          {
            reverseProxy = {
              enable = true;
              caddyfile = ''

              '';
            };
            telemetry.enable = true;
            faktory.enable = true;

            portfolio.enable = true;
          }
        ];
      };
    };
}
