{
  dockerTools,
  serverPort ? 7419,
  uiPort ? 7420,
}:
let
  baseImage = dockerTools.pullImage {
    imageName = "contribsys/faktory";
    finalImageTag = "1.9.3";
    os = "linux";
    arch = "amd64";
    imageDigest = "sha256:ccaa5df6a445ee678a7a95822e32e3cc8a5d41d70ebda75b82111d4e678c249c";
    sha256 = "sha256-jujSjxVH67SF+h9cBy8AUysBtYnUfiQyoyn4tkYHLMA=";
  };
in
(dockerTools.buildImage {
  name = "web-server-faktory";
  tag = "latest";
  fromImage = baseImage;

  config = {
    Entrypoint = [ "/faktory" ];
    Cmd = [
      "-b"
      ":${toString serverPort}"
      "-w"
      ":${toString uiPort}"
    ];
    ExposedPorts = {
      "${toString serverPort}/tcp" = { };
      "${toString uiPort}/tcp" = { };
    };
  };
}).overrideAttrs
  {
    passthru.ports = {
      server = serverPort;
      ui = uiPort;
    };
  }
