{
  docker,
  dockerCompose,
  lib,
  writeShellApplication,
}:
writeShellApplication {
  name = "run-docker-compose";
  runtimeInputs = [ docker ];
  text = ''
    ${lib.concatMapStringsSep "\n" (img: ''
      echo "Loading ${img.imageName}:${img.imageTag}..."
      docker load < ${img}
    '') dockerCompose.images}
    echo "Starting Docker Compose..."
    if [ -f .env ]; then
      docker compose --file ${dockerCompose} --env-file .env up
    else
      echo "Warning: .env file not found in current directory"
      docker compose --file ${dockerCompose} up
    fi
  '';
}
