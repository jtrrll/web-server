{
  buildEnv,
  dockerTools,
  formats,
  port ? 9009,
  runCommand,
}:
let
  baseImage = dockerTools.pullImage {
    imageName = "grafana/mimir";
    finalImageTag = "2.17.5";
    os = "linux";
    arch = "amd64";
    imageDigest = "sha256:0a30b23f18ca58cf038b56caed30a4f9282da1aad9832f3208daf0b5b969f77c";
    sha256 = "sha256-JEQvTrtHk08xFOZ4vhngLBnpI9IUhyUu1vYf0lhjrGA=";
  };
  config = (formats.yaml { }).generate "config.yaml" {
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
      "${toString port}/tcp" = { };
    };
  };
}).overrideAttrs
  {
    passthru.ports = {
      server = port;
    };
  }
