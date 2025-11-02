{
  buildEnv,
  dockerTools,
  lokiPort,
  mimirPort,
  runCommand,
  tempoPort,
  writeYAMLFile,
  port ? 3000,
}:
let
  baseImage = dockerTools.pullImage {
    imageName = "grafana/grafana";
    imageDigest = "sha256:74144189b38447facf737dfd0f3906e42e0776212bf575dc3334c3609183adf7";
    sha256 = "sha256-QfgZ60XFtTKmnjXR9PaPt7l3MOJbcbE95ASQzdhekSM=";
  };
  datasourcesConfig = writeYAMLFile "datasources.yaml" {
    apiVersion = 1;
    datasources = [
      {
        name = "Loki";
        type = "loki";
        access = "proxy";
        url = "http://loki:${builtins.toString lokiPort}";
        isDefault = false;
      }
      {
        name = "Mimir";
        type = "prometheus";
        access = "proxy";
        url = "http://mimir:${builtins.toString mimirPort}/prometheus";
        isDefault = true;
      }
      {
        name = "Tempo";
        type = "tempo";
        access = "proxy";
        url = "http://tempo:${builtins.toString tempoPort}";
        isDefault = false;
      }
    ];
  };
in
(dockerTools.buildImage {
  name = "web-server-grafana";
  tag = "latest";
  fromImage = baseImage;

  copyToRoot = buildEnv {
    name = "image-root";
    paths = [
      (runCommand "grafana-provisioning" { } ''
        mkdir -p $out/etc/grafana/provisioning/datasources
        cp ${datasourcesConfig} $out/etc/grafana/provisioning/datasources/datasources.yaml
      '')
    ];
  };

  config = {
    Entrypoint = [ "/run.sh" ];
    Env = [
      "GF_AUTH_PROXY_ENABLED=true"
      "GF_SERVER_HTTP_PORT=${builtins.toString port}"
      "GF_SERVER_ROOT_URL=/grafana"
      "GF_SERVER_SERVE_FROM_SUB_PATH=true"
    ];
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
