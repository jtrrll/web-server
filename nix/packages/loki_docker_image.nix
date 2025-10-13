{
  dockerTools,
  port ? 3100,
}:
let
  baseImage = dockerTools.pullImage {
    imageName = "grafana/loki";
    imageDigest = "sha256:2b10e3c0ba66ee115c018736b351c435006c809d32ea2c14be62be88d80f8372";
    sha256 = "sha256-cMnKv2haz1lZq396BYJLLM2IdMuoCupbGB5PWazDCP0=";
  };
in
(dockerTools.buildImage {
  name = "web-server-loki";
  tag = "latest";
  fromImage = baseImage;

  config = {
    Entrypoint = [ "/usr/bin/loki" ];
    Env = [ "LOKI_SERVER_HTTP_LISTEN_PORT=${builtins.toString port}" ];
    Cmd = [ "-config.file=/etc/loki/local-config.yaml" ];
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
