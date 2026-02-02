{
  buildEnv,
  busybox,
  dockerTools,
  runCommand,
  writeTextFile,
}:
let
  crontab = writeTextFile {
    name = "crontab";
    text = ''
      # Add cron jobs here
      # Example: */5 * * * * /usr/local/bin/example-job.sh
    '';
  };
in
dockerTools.buildImage {
  name = "web-server-cron";
  tag = "latest";

  copyToRoot = buildEnv {
    name = "image-root";
    paths = [
      busybox
      (runCommand "crontab" { } ''
        mkdir -p $out/etc/crontabs
        cp ${crontab} $out/etc/crontabs/root
      '')
    ];
    pathsToLink = [
      "/bin"
      "/etc"
    ];
  };
  config = {
    Cmd = [
      "/bin/crond"
      "-f"
      "-l"
      "2"
    ];
  };
}
