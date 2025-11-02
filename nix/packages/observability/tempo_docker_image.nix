{
  buildEnv,
  dockerTools,
  port ? 3200,
  runCommand,
  writeYAMLFile,
}:
let
  baseImage = dockerTools.pullImage {
    imageName = "grafana/tempo";
    imageDigest = "sha256:33975cde5fe87fbcc27942dddfded9fcecec153571a72b30b3cdcc863f7193a0";
    sha256 = "sha256-IxfqqZoMG5GArRHGDxLI6lDZp+ZO54y/QyvbD5g18gc=";
  };
  tempoConfig = writeYAMLFile "config.yaml" {
    server.http_listen_port = port;
    distributor.receivers.otlp.protocols = {
      grpc = { };
      http = { };
    };
    storage.trace = {
      backend = "local";
      local.path = "/tmp/tempo/traces";
    };
    compactor.compaction.block_retention = "48h";
  };
in
(dockerTools.buildImage {
  name = "web-server-tempo";
  tag = "latest";
  fromImage = baseImage;

  copyToRoot = buildEnv {
    name = "image-root";
    paths = [
      (runCommand "tempo-config" { } ''
        mkdir -p $out/etc/tempo
        cp ${tempoConfig} $out/etc/tempo/config.yaml
      '')
    ];
  };

  config = {
    Entrypoint = [ "/tempo" ];
    Cmd = [ "-config.file=/etc/tempo/config.yaml" ];
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
