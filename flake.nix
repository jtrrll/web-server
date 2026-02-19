{
  description = "jtrrll's multipurpose web server";

  inputs = {
    ### Development dependencies ###
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    devenv = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:cachix/devenv";
    };
    flake-parts = {
      inputs.nixpkgs-lib.follows = "nixpkgs";
      url = "github:hercules-ci/flake-parts";
    };
    import-tree.url = "github:vic/import-tree";
    justix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:jtrrll/justix";
    };
    snekcheck = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:jtrrll/snekcheck";
    };
    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };

    ### Service dependencies ###
    portfolio.url = "github:jtrrll/portfolio";
  };

  outputs =
    {
      flake-parts,
      import-tree,
      nixpkgs,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } (
      let
        modules-tree = nixpkgs.lib.pipe import-tree [
          (it: it.addPath ./modules)
          # Matches top-level `*.nix` files and `default.nix` files that are one level deep.
          (it: it.match "^/[^/]+\.nix$|^/[^/]+/default\.nix$")
        ];
      in
      {
        imports = [
          ./dev_shells
          ./servers
          modules-tree.result
        ];

        flake.lib.modules-tree = modules-tree;

        systems = nixpkgs.lib.systems.flakeExposed;
      }
    );
}
