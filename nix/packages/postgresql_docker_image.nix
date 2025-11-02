{
  buildEnv,
  coreutils,
  dockerTools,
  lib,
  postgresql,
  runCommand,
  port ? 5432,
}:
(dockerTools.buildImage {
  name = "web-server-postgresql";
  tag = "latest";

  copyToRoot = buildEnv {
    name = "image-root";
    paths = [
      coreutils
      postgresql
      (runCommand "postgres-dirs" { } ''
        mkdir -p $out/var/lib/postgresql/data
        mkdir -p $out/run/postgresql
      '')
    ];
  };

  config = {
    Env = [
      "POSTGRES_DB=\${POSTGRES_DB}"
      "POSTGRES_USER=\${POSTGRES_USER}"
      "POSTGRES_PASSWORD=\${POSTGRES_PASSWORD}"
      "PGDATA=/var/lib/postgresql/data"
    ];
    ExposedPorts = {
      "${builtins.toString port}/tcp" = { };
    };
    Cmd = [
      "${lib.getExe' postgresql "postgres"}"
      "-c"
      "listen_addresses=*"
      "-c"
      "port=${builtins.toString port}"
    ];
  };
}).overrideAttrs
  {
    passthru = {
      ports.server = port;
      inherit postgresql;
    };
  }
