{
  description = "jtrrll's multipurpose web server";

  inputs = {
    devenv.url = "github:cachix/devenv";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = {
    devenv,
    flake-parts,
    ...
  } @ inputs: let
    constants = import ./constants.nix;
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      flake = {
      };
      perSystem = {pkgs, ...}: {
        _module.args = {inherit constants;};
        imports = [./apps];
        devShells.default = devenv.lib.mkShell {
          inherit inputs pkgs;
          modules = [./devshell.nix];
        };
        formatter = pkgs.alejandra;
      };

      systems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    };
}
