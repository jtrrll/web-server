{
  dockerTools,
  port ? 3000,
}:
let
  baseImage = dockerTools.pullImage {
    imageName = "grafana/grafana";
    imageDigest = "sha256:74144189b38447facf737dfd0f3906e42e0776212bf575dc3334c3609183adf7";
    sha256 = "sha256-QfgZ60XFtTKmnjXR9PaPt7l3MOJbcbE95ASQzdhekSM=";
  };
in
(dockerTools.buildImage {
  name = "web-server-grafana";
  tag = "latest";
  fromImage = baseImage;

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
