{
  buildEnv,
  dockerTools,
  formats,
  queryPort ? 16686,
  runCommand,
}:
let
  baseImage = dockerTools.pullImage {
    imageName = "jaegertracing/jaeger";
    imageDigest = "sha256:b585df1b6299bbbd16bf7c679da30389349736e4b6bc8f4f500142a75bf26ca8";
    sha256 = "sha256-rss+ptRH7E0giNzFhZwITqNbPVqffvdkKUV4F0vrtac=";
  };
  config = writeYAMLFile "jaeger-config" {
    extensions = {
      jaeger_query = {
        base_path = "/jaeger";
        http.endpoint = "0.0.0.0:${builtins.toString queryPort}";
        storage.traces = "default_storage";
        ui = { };
      };
      jaeger_storage = {
        backends = {
          default_storage = {
            memory.max_traces = 10000;
          };
        };
      };
    };
    service = {
      extensions = [
        "jaeger_query"
        "jaeger_storage"
      ];
      pipelines = {
        traces = {
          receivers = [ "nop" ];
          processors = [ "batch" ];
          exporters = [ "nop" ];
        };
      };
      telemetry = {
        resource.service = "jaeger";
        metrics.level = "detailed";
        logs.level = "info";
      };
    };
    receivers.nop = { };
    processors.batch = { };
    exporters.nop = { };
  };
  writeYAMLFile = (formats.yaml { }).generate;
in
(dockerTools.buildImage {
  name = "web-server-jaeger";
  tag = "latest";
  fromImage = baseImage;

  copyToRoot = buildEnv {
    name = "image-root";
    paths = [
      (runCommand "jaeger-config" { } ''
        mkdir -p $out/etc/jaeger
        cp ${config} $out/etc/jaeger/config.yaml
      '')
    ];
  };
  config = {
    Entrypoint = [ "/cmd/jaeger/jaeger-linux" ];
    Cmd = [
      "--config"
      "/etc/jaeger/config.yaml"
    ];
    ExposedPorts = {
      "${builtins.toString queryPort}/tcp" = { };
    };
  };
}).overrideAttrs
  {
    passthru.ports = {
      queryServer = queryPort;
    };
  }
