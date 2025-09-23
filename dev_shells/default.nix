{ inputs, ... }:
{
  imports = [ inputs.devenv.flakeModule ];
  perSystem =
    {
      lib,
      pkgs,
      ...
    }:
    {
      devenv = builtins.addErrorContext "while defining devenv" {
        modules = [
          {
            containers = lib.mkForce { }; # Workaround to remove containers from flake checks.
          }
        ];
        shells.default = builtins.addErrorContext "while defining default devenv shell" {
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
              markdownlint.enable = true;
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
              shellcheck.enable = true;
              shfmt.enable = true;
              statix.enable = true;
            };
          };

          languages.nix.enable = true;
          packages = [ pkgs.nix-tree ];
        };
      };
    };
}
