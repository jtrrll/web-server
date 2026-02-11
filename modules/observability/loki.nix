{
  dockerTools,
  port ? 3100,
}:
let
  baseImage = dockerTools.pullImage {
    imageName = "grafana/loki";
    finalImageTag = "3.6.5";
    os = "linux";
    arch = "amd64";
    imageDigest = "sha256:146a6add37403d7f74aa17f52a849de9babf24f92890613cacf346e12a969efc";
    sha256 = "sha256-Wk3gOMI3ev2iminSM/UO3Dj8Do2TzMbT2VdX/FJ+1Gg=";
  };
in
(dockerTools.buildImage {
  name = "web-server-loki";
  tag = "latest";
  fromImage = baseImage;

  config = {
    Entrypoint = [ "/usr/bin/loki" ];
    Env = [ "LOKI_SERVER_HTTP_LISTEN_PORT=${toString port}" ];
    Cmd = [ "-config.file=/etc/loki/local-config.yaml" ];
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
