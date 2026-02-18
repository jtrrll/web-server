{ flake-parts-lib, ... }:
{
  options.perSystem = flake-parts-lib.mkPerSystemOption (
    { lib, ... }:
    {
      options.server = {
        services = lib.mkOption {
          type = lib.types.attrsOf (
            lib.types.submodule {
              options = {
                enable = lib.mkEnableOption "this service";
                image = lib.mkOption {
                  type = lib.types.package;
                  description = "The image derivation for this service";
                };
                ports = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "The port mappings to expose to the host";
                  example = "80:8080";
                };
                networks = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "A list of accessible networks";
                };
                volumes = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "The volumes mounted for the service";
                  example = [
                    "/nix/store/.../Caddyfile:/etc/caddy/Caddyfile:ro"
                    "data:/var/lib/data"
                  ];
                };
              };
            }
          );
          default = { };
          description = "Service definitions for the server";
        };

        networks = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = "Network definitions for the server";
        };

        volumes = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = "Volume definitions for the server";
        };
      };
    }
  );

  config.perSystem =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      packages =
        let
          enabledServices = lib.filterAttrs (_: svc: svc.enable) config.server.services;
          images = lib.attrValues (lib.mapAttrs (_: svc: svc.image) enabledServices);
        in
        {
          default = pkgs.callPackage (
            { lib }:
            pkgs.runCommand "release-bundle" { } ''
              mkdir -p $out
              ln -s ${config.packages.dockerCompose} $out/docker_compose.yaml
              ln -s ${config.packages.deployScript} $out/deploy
              mkdir -p $out/images
              ${lib.concatMapStringsSep "\n" (img: ''
                ln -s ${img} $out/images/${img.imageName}-${img.imageTag}.tar.gz
              '') images}
            ''
          ) { };
          deployScript = pkgs.callPackage (
            { lib, writeShellScript }:
            writeShellScript "deploy" ''
              set -euo pipefail

              echo "Loading Docker images..."
              ${lib.concatMapStringsSep "\n" (img: ''
                echo "  Loading ${img.imageName}:${img.imageTag}..."
                docker load < ${img}
              '') images}

              echo "Starting services with docker compose..."
              docker compose -f ${config.packages.dockerCompose} up -d --remove-orphans

              echo "Deployment complete!"
              echo ""
              echo "Running services:"
              docker compose -f ${config.packages.dockerCompose} ps
            ''
          ) { };
          dockerCompose =
            let
              mkService =
                _: svc:
                {
                  image = "${svc.image.imageName}:${svc.image.imageTag}";
                }
                // lib.optionalAttrs (svc.ports != [ ]) { inherit (svc) ports; }
                // lib.optionalAttrs (svc.volumes != [ ]) { inherit (svc) volumes; }
                // lib.optionalAttrs (svc.networks != [ ]) { inherit (svc) networks; };

              services = lib.mapAttrs mkService enabledServices;
              inherit (config.server) networks volumes;

              composeConfig = {
                inherit services;
              }
              // lib.optionalAttrs (networks != { }) { inherit networks; }
              // lib.optionalAttrs (volumes != { }) { inherit volumes; };
            in
            (pkgs.formats.yaml { }).generate "docker_compose.yaml" composeConfig;
        };
    };
}
