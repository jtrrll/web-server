{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      apps = builtins.addErrorContext "while defining apps" {
        default = {
          type = "app";
          program = pkgs.callPackage ./docker_compose.nix {
            inherit (config.packages) dockerCompose;
          };
        };
      };
    };
}
