# web-server

<!-- markdownlint-disable MD013 -->
![GitHub Actions CI Status](https://img.shields.io/github/actions/workflow/status/jtrrll/web-server/ci.yaml?branch=main&logo=github&label=CI)
![License](https://img.shields.io/github/license/jtrrll/web-server?label=License)
<!-- markdownlint-enable MD013 -->

jtrrll's multipurpose web server.

## Usage

1. [Install Nix](https://zero-to-nix.com/start/install)
2. Run the following to start the `nginx` reverse proxy service:

   <!-- markdownlint-disable MD013 -->
   ```sh
   sudo nix run .#nginx --extra-experimental-features nix-command --extra-experimental-features flakes
   ```
   <!-- markdownlint-enable MD013 -->

3. Run additional services by running the following:

   ```sh
   nix run .#<name>
   ```
