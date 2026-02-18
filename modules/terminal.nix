{
  perSystem =
    {
      config,
      pkgs,
      ...
    }:
    {
      server.services.terminal = {
        image = config.packages.ttydDockerImage;
      };
      packages.ttydDockerImage =
        pkgs.callPackage
          (
            {
              buildEnv,
              dockerTools,
              nix,
              runCommand,
              writeTextFile,
              port ? 7681,
            }:
            let
              baseImage = dockerTools.pullImage {
                imageName = "tsl0922/ttyd";
                finalImageTag = "latest";
                os = "linux";
                arch = "amd64";
                imageDigest = "sha256:41939c3fd23c65b52a7060691312f37e09c41822d31ddc82b0321e9bbeb636d5";
                sha256 = "sha256-GLY4RPmGz6LP0ogDLqIrBkI1Eowznse2EovlXoEJmIU=";
              };
              nixConf = writeTextFile {
                name = "nix.conf";
                text = ''
                  experimental-features = flakes nix-command
                '';
              };
            in
            (dockerTools.buildLayeredImage {
              name = "web-server-ttyd";
              tag = "latest";
              fromImage = baseImage;

              copyToRoot = buildEnv {
                name = "image-root";
                paths = [
                  nix
                  (runCommand "nix-config" { } ''
                    mkdir -p $out/etc/nix
                    cp ${nixConf} $out/etc/nix/nix.conf
                  '')
                ];
              };

              config = {
                Entrypoint = [ "/usr/bin/ttyd" ];
                Cmd = [
                  "--writable"
                  "--port"
                  (toString port)
                  "bash"
                ];
                ExposedPorts = {
                  "${toString port}/tcp" = { };
                };
              };
            }).overrideAttrs
              {
                passthru.ports = {
                  server = port;
                };
              }
          )
          {
          };
    };
}
