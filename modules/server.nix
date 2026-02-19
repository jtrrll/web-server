{
  inputs,
  self,
  lib,
  ...
}:
{
  imports = [ inputs.flake-parts.flakeModules.modules ];

  flake = {
    modules.server.default =
      { lib, ... }:
      {
        options = {
          services = lib.mkOption {
            type = lib.types.attrsOf (
              lib.types.submodule {
                options = {
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
                  environment = lib.mkOption {
                    type = lib.types.attrsOf (
                      lib.types.oneOf [
                        lib.types.str
                        lib.types.bool
                        lib.types.int
                        lib.types.float
                      ]
                    );
                    default = { };
                    description = "Environment variables passed to the container";
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
      };

    lib.mkServer =
      {
        pkgs,
        modules ? [ ],
      }:
      let
        resolved = lib.evalModules {
          modules =
            (lib.attrValues self.modules.server)
            ++ modules
            ++ [
              {
                _module.args = {
                  inherit lib pkgs;
                };
              }
            ];
        };

        images = lib.attrValues (lib.mapAttrs (_: svc: svc.image) resolved.config.services);

        mkService =
          _: svc:
          {
            image = "${svc.image.imageName}:${svc.image.imageTag}";
          }
          // lib.optionalAttrs (svc.ports != [ ]) { inherit (svc) ports; }
          // lib.optionalAttrs (svc.volumes != [ ]) { inherit (svc) volumes; }
          // lib.optionalAttrs (svc.networks != [ ]) { inherit (svc) networks; }
          // lib.optionalAttrs (svc.environment != { }) { inherit (svc) environment; };

        services = lib.mapAttrs mkService resolved.config.services;
        inherit (resolved.config) networks volumes;

        composeConfig = {
          inherit services;
        }
        // lib.optionalAttrs (networks != { }) { inherit networks; }
        // lib.optionalAttrs (volumes != { }) { inherit volumes; };

        dockerCompose = self.packages.${pkgs.stdenv.system}.dockerCompose.override {
          inherit composeConfig;
        };

        deployScript = pkgs.writeScript "deploy" ''
          #!/usr/bin/env bash
          set -euo pipefail
          BUNDLE_DIR="$(dirname "$0")"

          echo "Loading Docker images..."
          for img in "$BUNDLE_DIR"/images/*.tar.gz; do
            echo "  Loading $img..."
            docker load < "$img"
          done

          echo "Starting services with docker compose..."
          docker compose --project-directory . --file "$BUNDLE_DIR/docker_compose.yaml" up -d --remove-orphans

          echo "Deployment complete!"
          echo ""
          echo "Running services:"
          docker compose --project-directory . --file "$BUNDLE_DIR/docker_compose.yaml" ps
        '';
      in
      pkgs.runCommand "release-bundle" { } ''
        mkdir -p $out/images
        cp ${dockerCompose} $out/docker_compose.yaml
        cp ${deployScript} $out/deploy
        chmod +x $out/deploy
        ${lib.concatMapStringsSep "\n" (img: ''
          cp ${img} $out/images/${
            lib.replaceStrings [ "/" "-" ] [ "_" "_" ] (
              lib.concatStringsSep "_" [
                img.imageName
                img.imageTag
              ]
            )
          }.tar.gz
        '') images}
      '';
  };

  perSystem =
    { config, pkgs, ... }:
    {
      packages = {
        deployScript =
          pkgs.callPackage
            (
              {
                dockerCompose,
                images,
                lib,
                writeShellScript,
              }:
              writeShellScript "deploy" ''
                set -euo pipefail

                echo "Loading Docker images..."
                ${lib.concatMapStringsSep "\n" (img: ''
                  echo "  Loading ${img.imageName}:${img.imageTag}..."
                  docker load < ${img}
                '') images}

                echo "Starting services with docker compose..."
                docker compose -f ${dockerCompose} up -d --remove-orphans

                echo "Deployment complete!"
                echo ""
                echo "Running services:"
                docker compose -f ${dockerCompose} ps
              ''
            )
            {
              inherit (config.packages) dockerCompose;
              images = [ ];
            };
        dockerCompose =
          pkgs.callPackage
            ({ composeConfig, formats }: (formats.yaml { }).generate "docker_compose.yaml" composeConfig)
            {
              composeConfig = { };
            };
      };
    };
}
