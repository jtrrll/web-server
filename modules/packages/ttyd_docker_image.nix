{
  buildEnv,
  dockerTools,
  nix,
  runCommand,
  writeTextFile,
  port ? 7681,
}:
let
  baseImage = dockerTools.pullImage {
    imageName = "tsl0922/ttyd";
    imageDigest = "sha256:31190972b97c7f1e1958f8d6af9b280602cf797a02dc9deff77565669bd66306";
    sha256 = "sha256-kR+I+kSOk2roga6wPGt7OAXG3aPv23Gqkp+Awj0hiPA=";
  };
  nixConf = writeTextFile {
    name = "nix.conf";
    text = ''
      experimental-features = flakes nix-command
    '';
  };
in
(dockerTools.buildImage {
  name = "web-server-ttyd";
  tag = "latest";
  fromImage = baseImage;

  copyToRoot = buildEnv {
    name = "image-root";
    paths = [
      nix
      (runCommand "nix-config" { } ''
        mkdir -p $out/etc/nix
        cp ${nixConf} $out/etc/nix/nix.conf
      '')
    ];
  };

  config = {
    Entrypoint = [ "/usr/bin/ttyd" ];
    Cmd = [
      "--writable"
      "--port"
      (builtins.toString port)
      "bash"
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
