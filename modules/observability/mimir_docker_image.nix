{
  buildEnv,
  dockerTools,
  port ? 9009,
  runCommand,
  writeYAMLFile,
}:
let
  baseImage = dockerTools.pullImage {
    imageName = "grafana/mimir";
    imageDigest = "sha256:dfa02581c519a28e2ce50c7304d05a635bb1e14b36e2f8a7a54815b36d4d1f9b";
    sha256 = "sha256-dY9OQabObJdbIrShrfjfoIRRG3RSLOHd/o02gwle/Vk=";
  };
  config = writeYAMLFile "config.yaml" {
    target = "all";
    server.http_listen_port = port;
    common.storage = {
      backend = "filesystem";
      filesystem.dir = "/data";
    };
    blocks_storage.filesystem.dir = "/data/blocks";
  };
in
(dockerTools.buildImage {
  name = "web-server-mimir";
  tag = "latest";
  fromImage = baseImage;

  copyToRoot = buildEnv {
    name = "image-root";
    paths = [
      (runCommand "mimir-config" { } ''
        mkdir -p $out/etc/mimir
        cp ${config} $out/etc/mimir/config.yaml
      '')
    ];
  };

  config = {
    Entrypoint = [ "/bin/mimir" ];
    Cmd = [ "-config.file=/etc/mimir/config.yaml" ];
    ExposedPorts = {
      "${builtins.toString port}/tcp" = { };
    };
  };
}).overrideAttrs
  {
    passthru.ports = {
      server = port;
    };
  }
