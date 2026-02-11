{
  buildEnv,
  dockerTools,
  formats,
  lokiPort,
  mimirPort,
  runCommand,
  tempoPort,
  grpcPort ? 4317,
  httpPort ? 4318,
}:
let
  baseImage = dockerTools.pullImage {
    imageName = "otel/opentelemetry-collector-contrib";
    finalImageTag = "0.145.0";
    os = "linux";
    arch = "amd64";
    imageDigest = "sha256:ac7ad5529b8cf522aa03792bb6d667a7df7d2c3f3da40b2746c51c113ea28c8c";
    sha256 = "sha256-UheuoS3pVf3tr0Dxp48GKdjOtPinIvJX77yXHyX6k8o=";
  };
  config = (formats.yaml { }).generate "config.yaml" {
    receivers.otlp.protocols = {
      grpc.endpoint = "0.0.0.0:${toString grpcPort}";
      http.endpoint = "0.0.0.0:${toString httpPort}";
    };
    exporters = {
      otlp = {
        endpoint = "tempo:${toString tempoPort}";
        tls.insecure = true;
      };
      prometheusremotewrite = {
        endpoint = "http://mimir:${toString mimirPort}/api/v1/push";
      };
      loki = {
        endpoint = "http://loki:${toString lokiPort}/loki/api/v1/push";
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
      "${toString grpcPort}/tcp" = { };
      "${toString httpPort}/tcp" = { };
    };
  };
}).overrideAttrs
  {
    passthru.ports = {
      grpc = grpcPort;
      http = httpPort;
    };
  }
