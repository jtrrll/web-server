{
  caddyDockerImage,
  formats,
  serviceDockerImages ? { },
}:
let
  writeYAMLFile = (formats.yaml { }).generate;
  mkService = _: dockerImage: {
    image = "${dockerImage.imageName}:${dockerImage.imageTag}";
    expose = builtins.attrValues dockerImage.ports;
  };
  services = {
    caddy = {
      image = "${caddyDockerImage.imageName}:${caddyDockerImage.imageTag}";
      depends_on = builtins.attrNames serviceDockerImages;
      env_file = [ ".env" ];
      ports = [
        "80:${builtins.toString caddyDockerImage.ports.HTTP}"
        "443:${builtins.toString caddyDockerImage.ports.HTTPS}"
      ];
      volumes = [
        "caddy_config:/config"
        "caddy_data:/data"
      ];
    };
  }
  // builtins.mapAttrs mkService serviceDockerImages;
in
writeYAMLFile "docker_compose.yaml" {
  inherit services;
  volumes = {
    "caddy_config" = { };
    "caddy_data" = { };
  };
}
