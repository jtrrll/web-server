{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        cronDockerImage = pkgs.callPackage ./cron_docker_image.nix {
          inherit (inputs.nixpkgs.legacyPackages."x86_64-linux") busybox;
        };
        faktoryDockerImage = pkgs.callPackage ./faktory_docker_image.nix { };
      };
    };
}
