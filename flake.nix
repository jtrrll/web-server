{
  description = "jtrrll's multipurpose web server";

  inputs = {
    devenv.url = "github:cachix/devenv";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    snekcheck.url = "github:jtrrll/snekcheck";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    {
      flake-parts,
      nixpkgs,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./checks
        ./dev_shells
        ./formatter
      ];
      systems = nixpkgs.lib.systems.flakeExposed;
    };
}
