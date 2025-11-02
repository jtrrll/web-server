{
  caddyDockerImage,
  writeYAMLFile,
  serviceDockerImages ? { },
}:
let
  mkService =
    _: dockerImage:
    {
      image = "${dockerImage.imageName}:${dockerImage.imageTag}";
    }
    // (if dockerImage ? ports then { expose = builtins.attrValues dockerImage.ports; } else { });
  services = {
    caddy = {
      image = "${caddyDockerImage.imageName}:${caddyDockerImage.imageTag}";
      depends_on = builtins.attrNames serviceDockerImages;
      environment = {
        ADMIN_USERNAME = "\${ADMIN_USERNAME}";
        ADMIN_PASSWORD_HASHED = "\${ADMIN_PASSWORD_HASHED}";
      };
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
(writeYAMLFile "docker_compose.yaml" {
  inherit services;
  volumes = {
    "caddy_config" = { };
    "caddy_data" = { };
  };
}).overrideAttrs
  {
    passthru.images = [ caddyDockerImage ] ++ builtins.attrValues serviceDockerImages;
  }
