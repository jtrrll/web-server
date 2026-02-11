{
  buildEnv,
  dockerTools,
  formats,
  port ? 3200,
  runCommand,
}:
let
  baseImage = dockerTools.pullImage {
    imageName = "grafana/tempo";
    finalImageTag = "2.10.0";
    os = "linux";
    arch = "amd64";
    imageDigest = "sha256:0b85bc67c5c5fa6bc1f8e58a01bfeb741dff6e1c6be89d2a15be9f7ff975ff30";
    sha256 = "sha256-FWI28Eb+3Q1EB+mUkymQCaT4XZW/PNVEttUsO4t658I=";
  };
  tempoConfig = (formats.yaml { }).generate "config.yaml" {
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
      "${toString port}/tcp" = { };
    };
  };
}).overrideAttrs
  {
    passthru.ports = {
      server = port;
    };
  }
