{ inputs, self, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];

  perSystem =
    { inputs', pkgs, ... }:
    {
      checks.snekcheck =
        pkgs.runCommandLocal "snekcheck"
          {
            buildInputs = [ inputs'.snekcheck.packages.default ];
          }
          ''
            find ${self}/** -exec snekcheck {} +
            touch $out
          '';
      treefmt.programs = {
        deadnix.enable = true;
        keep-sorted.enable = true;
        nixfmt.enable = true;
        statix.enable = true;
        yamlfmt.enable = true;
      };
    };
}
