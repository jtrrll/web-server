{
  buildEnv,
  dockerTools,
  lib,
  port ? 8080,
  portfolio,
}:
(dockerTools.buildImage {
  name = portfolio.pname;
  tag = portfolio.version;

  copyToRoot = buildEnv {
    name = "image-root";
    paths = [ portfolio ];
    pathsToLink = [ "/bin" ];
  };
  config = {
    Cmd = [
      (lib.getExe portfolio)
      "--port"
      "${builtins.toString port}"
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
