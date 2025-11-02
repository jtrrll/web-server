{
  description = "jtrrll's multipurpose web server";

  inputs = {
    devenv.url = "github:cachix/devenv";
    dotfiles.url = "github:jtrrll/dotfiles";
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    portfolio.url = "github:jtrrll/portfolio";
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
      imports = [ ./nix ];
      systems = nixpkgs.lib.systems.flakeExposed;
    };
}
