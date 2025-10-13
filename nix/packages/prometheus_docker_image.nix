{
  dockerTools,
  port ? 9090,
}:
let
  baseImage = dockerTools.pullImage {
    imageName = "prom/prometheus";
    imageDigest = "sha256:cc9ed880c087365fb86368e2d0ea38106819ab34f00ae56017a854ad3c68ff0f";
    sha256 = "sha256-cwu64Qc5TaNSW13AOA2ObHKhKlZq5VrTuxRucyyOKRE=";
  };
in
(dockerTools.buildImage {
  name = "web-server-prometheus";
  tag = "latest";
  fromImage = baseImage;

  config = {
    Entrypoint = [ "/bin/prometheus" ];
    Cmd = [
      "--config.file=/etc/prometheus/prometheus.yml"
      "--storage.tsdb.path=/prometheus"
      "--web.listen-address=:${builtins.toString port}"
      "--web.route-prefix=/prometheus"
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
