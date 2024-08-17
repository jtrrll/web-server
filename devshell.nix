{pkgs, ...}: {
  enterShell = ''
    printf "                __
     _      _____  / /_        ________  ______   _____  _____
    | | /| / / _ \/ __ \______/ ___/ _ \/ ___/ | / / _ \/ ___/
    | |/ |/ /  __/ /_/ /_____(__  )  __/ /   | |/ /  __/ /
    |__/|__/\___/_.___/     /____/\___/_/    |___/\___/_/\n" | ${pkgs.lolcat}/bin/lolcat
    printf "\033[0;1;36mDEVSHELL ACTIVATED\033[0m\n"
  '';
  languages = {
    nix.enable = true;
  };
  packages = [
    pkgs.commitizen
  ];
  pre-commit = {
    default_stages = ["pre-push"];
    hooks = {
      actionlint.enable = true;
      alejandra.enable = true;
      check-added-large-files = {
        enable = true;
        stages = ["pre-commit"];
      };
      check-yaml.enable = true;
      commitizen.enable = true;
      deadnix.enable = true;
      detect-private-keys = {
        enable = true;
        stages = ["pre-commit"];
      };
      end-of-file-fixer.enable = true;
      flake-checker.enable = true;
      markdownlint.enable = true;
      mixed-line-endings.enable = true;
      nil.enable = true;
      no-commit-to-branch = {
        enable = true;
        stages = ["pre-commit"];
      };
      ripsecrets = {
        enable = true;
        stages = ["pre-commit"];
      };
      shellcheck.enable = true;
      shfmt.enable = true;
      statix.enable = true;
    };
  };
}
