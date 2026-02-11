{
  buildEnv,
  dockerTools,
  formats,
  lokiPort,
  mimirPort,
  runCommand,
  tempoPort,
  port ? 3000,
}:
let
  baseImage = dockerTools.pullImage {
    imageName = "grafana/grafana";
    finalImageTag = "main";
    os = "linux";
    arch = "amd64";
    imageDigest = "sha256:cf6c2fa8b9afc3dea45a012ffb4650891895f8fdbbf60593ef07221d8800c7b4";
    sha256 = "sha256-yo+uJ8/Kk0tQ6/e/WjAK/GFg4rlAaB+ffqVIZBNF20U=";
  };
  datasourcesConfig = (formats.yaml { }).generate "datasources.yaml" {
    apiVersion = 1;
    datasources = [
      {
        name = "Loki";
        type = "loki";
        access = "proxy";
        url = "http://loki:${toString lokiPort}";
        isDefault = false;
      }
      {
        name = "Mimir";
        type = "prometheus";
        access = "proxy";
        url = "http://mimir:${toString mimirPort}/prometheus";
        isDefault = true;
      }
      {
        name = "Tempo";
        type = "tempo";
        access = "proxy";
        url = "http://tempo:${toString tempoPort}";
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
      "GF_SERVER_HTTP_PORT=${toString port}"
      "GF_SERVER_ROOT_URL=/grafana"
      "GF_SERVER_SERVE_FROM_SUB_PATH=true"
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
