{ inputs, ... }:
{
  imports = [ inputs.devenv.flakeModule ];

  perSystem =
    {
      lib,
      pkgs,
      system,
      ...
    }:
    {
      devenv = {
        modules = (lib.attrValues inputs.justix.modules.devenv) ++ [
          {
            containers = lib.mkForce { }; # Workaround to remove containers from flake checks.
          }
        ];
        shells.default = {
          enterShell = lib.getExe (
            pkgs.writeShellApplication rec {
              meta.mainProgram = name;
              name = "splashScreen";
              runtimeInputs = [
                pkgs.lolcat
                pkgs.uutils-coreutils-noprefix
              ];
              text = ''
                printf "                __
                 _      _____  / /_        ________  ______   _____  _____
                | | /| / / _ \/ __ \______/ ___/ _ \/ ___/ | / / _ \/ ___/
                | |/ |/ /  __/ /_/ /_____(__  )  __/ /   | |/ /  __/ /
                |__/|__/\___/_.___/     /____/\___/_/    |___/\___/_/\n" | lolcat
                printf "\033[0;1;36mDEVSHELL ACTIVATED\033[0m\n"
              '';
            }
          );

          git-hooks = {
            default_stages = [ "pre-push" ];
            hooks = {
              actionlint.enable = true;
              check-added-large-files = {
                enable = true;
                stages = [ "pre-commit" ];
              };
              check-json.enable = true;
              check-yaml.enable = true;
              deadnix.enable = true;
              detect-private-keys = {
                enable = true;
                stages = [ "pre-commit" ];
              };
              end-of-file-fixer.enable = true;
              flake-checker.enable = true;
              fmt = {
                enable = true;
                entry = "just fmt";
                name = "fmt";
                pass_filenames = false;
              };
              markdownlint = {
                enable = true;
                settings.configuration = {
                  MD013.line_length = 120;
                };
              };
              mixed-line-endings.enable = true;
              nil.enable = true;
              no-commit-to-branch = {
                enable = true;
                stages = [ "pre-commit" ];
              };
              ripsecrets = {
                enable = true;
                stages = [ "pre-commit" ];
              };
              shellcheck = {
                enable = true;
                excludes = [ ".envrc" ];
              };
              shfmt.enable = true;
              statix.enable = true;
            };
          };

          justix = {
            enable = true;
            config.recipes = {
              build-image = {
                attributes.doc = "Builds and loads a single Docker image.";
                commands = ''
                  PACKAGE_NAME={{ image-name }}

                  echo "Building package: $PACKAGE_NAME"
                  nix build ".#$PACKAGE_NAME"

                  if [ ! -L "result" ]; then \
                    echo "Error: Build failed or result symlink not found" \
                    exit 1 \
                  fi
                  echo "Built package: $PACKAGE_NAME"

                  echo "Loading image: $PACKAGE_NAME"
                  docker load < result
                '';
                parameters = [ "image-name" ];
              };
              # TODO: Revist this
              # dev-compose = {
              #   commands = ''
              #     ${lib.getExe (
              #       config.apps.default.program.override {
              #         dockerCompose = config.packages.dockerCompose.override {
              #           caddyDockerImage = config.packages.caddyDockerImage.dev;
              #         };
              #       }
              #     )}
              #   '';
              # };
              fmt = {
                attributes.doc = "Formats and lints files";
                commands = ''
                  @find "{{ paths }}" ! -path '*/.*' -exec ${
                    lib.getExe inputs.snekcheck.packages.${system}.default
                  } --fix {} +
                  @nix fmt -- {{ paths }}
                '';
                parameters = [ "*paths='.'" ];
              };
              list = {
                attributes = {
                  default = true;
                  doc = "Lists available recipes";
                  private = true;
                };
                commands = "@just --list";
              };
            };
          };

          languages.nix = {
            enable = true;
            lsp.package = pkgs.nixd;
          };

          packages = [
            pkgs.docker
          ];
        };
      };
    };
}
