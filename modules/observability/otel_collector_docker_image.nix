{
  buildEnv,
  dockerTools,
  lokiPort,
  mimirPort,
  runCommand,
  tempoPort,
  writeYAMLFile,
  grpcPort ? 4317,
  httpPort ? 4318,
}:
let
  baseImage = dockerTools.pullImage {
    imageName = "otel/opentelemetry-collector-contrib";
    imageDigest = "sha256:fe9e49c677b0e3d35bc44a49e296751edcd43718c6aaed5f5011c61cce6156ed";
    sha256 = "sha256-x2KUh0V/Z2ynwY9S9KGEvJN1I83BQNmvemKwUQ79+HQ=";
  };
  config = writeYAMLFile "config.yaml" {
    receivers.otlp.protocols = {
      grpc.endpoint = "0.0.0.0:${builtins.toString grpcPort}";
      http.endpoint = "0.0.0.0:${builtins.toString httpPort}";
    };
    exporters = {
      otlp = {
        endpoint = "tempo:${builtins.toString tempoPort}";
        tls.insecure = true;
      };
      prometheusremotewrite = {
        endpoint = "http://mimir:${builtins.toString mimirPort}/api/v1/push";
      };
      loki = {
        endpoint = "http://loki:${builtins.toString lokiPort}/loki/api/v1/push";
      };
    };
    service = {
      pipelines = {
        traces = {
          receivers = [ "otlp" ];
          exporters = [ "otlp" ];
        };
        metrics = {
          receivers = [ "otlp" ];
          exporters = [ "prometheusremotewrite" ];
        };
        logs = {
          receivers = [ "otlp" ];
          exporters = [ "loki" ];
        };
      };
    };
  };
in
(dockerTools.buildImage {
  name = "web-server-otel-collector";
  tag = "latest";
  fromImage = baseImage;

  copyToRoot = buildEnv {
    name = "image-root";
    paths = [
      (runCommand "otel-config" { } ''
        mkdir -p $out/etc/otelcol-contrib
        cp ${config} $out/etc/otelcol-contrib/config.yaml
      '')
    ];
  };

  config = {
    Entrypoint = [ "/otelcol-contrib" ];
    Cmd = [ "--config=/etc/otelcol-contrib/config.yaml" ];
    ExposedPorts = {
      "${builtins.toString grpcPort}/tcp" = { };
      "${builtins.toString httpPort}/tcp" = { };
    };
  };
}).overrideAttrs
  {
    passthru.ports = {
      grpc = grpcPort;
      http = httpPort;
    };
  }
