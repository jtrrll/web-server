{
  dockerTools,
  serverPort ? 7419,
  uiPort ? 7420,
}:
let
  baseImage = dockerTools.pullImage {
    imageName = "contribsys/faktory";
    imageDigest = "sha256:37e502a3b947e030f1688d59f69e2f8ec83165ca4d0594f69cfe1a4f767d8161";
    sha256 = "sha256-Y6yaiKOAuZb2Tt0irObh13JU5/aUl7rfzL6NHji3xAQ=";
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
      ":${builtins.toString serverPort}"
      "-w"
      ":${builtins.toString uiPort}"
    ];
    ExposedPorts = {
      "${builtins.toString serverPort}/tcp" = { };
      "${builtins.toString uiPort}/tcp" = { };
    };
  };
}).overrideAttrs
  {
    passthru.ports = {
      server = serverPort;
      ui = uiPort;
    };
  }
