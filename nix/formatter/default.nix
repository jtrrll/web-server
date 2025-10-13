{ inputs, ... }:
{
  imports = [ inputs.treefmt-nix.flakeModule ];
  perSystem = _: {
    treefmt.programs = builtins.addErrorContext "while defining formatter" {
      deadnix.enable = true;
      nixfmt.enable = true;
      statix.enable = true;
    };
  };
}
