{
  config,
  lib,
  ...
}:
let
  # This is my little home brew impermanence :3
  # see, you don't need any external modules for that
  inherit (builtins) map;
  inherit (lib.strings) concatStringsSep;
  inherit (lib)
    mkMerge
    forEach
    mkDefault
    mkIf
    mkEnableOption
    mkOption
    types
    ;

  cfg = config.staypls;

  mkPersistentBindMounts =
    list:
    mkMerge (
      map (path: {
        "${path}" = {
          device = "/persist${path}";
          fsType = "none";
          options = [
            "bind"
            # no reason to trim bind mounts like that
            "X-fstrim.notrim"
            # hide the mounts cuz I dont wanna see them
            "x-gvfs-hide"
          ];
        };
      }) list
    );
  mkPersistentSourcePaths =
    list:
    concatStringsSep "\n" (
      forEach list (path: ''
        mkdir -p /sysroot${path} /sysroot/persist${path}
      '')
    );
  mkPersistentFileSources =
    list:
    concatStringsSep "\n" (
      forEach list (path: ''
        mkdir -p /sysroot${dirOf path} /sysroot/persist${dirOf path}
        touch /sysroot${path} /sysroot/persist${path}
        chmod 600 /sysroot${path} /sysroot/persist${path}
      '')
    );
in
{
  options.staypls = {
    enable = mkEnableOption "Enable directory impermanence module";
    dirs = mkOption {
      type = types.listOf types.str;
      description = "List of directiories to mount";
    };
    files = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "List of files to persist through bind mounts";
    };
  };
  config = mkIf cfg.enable {
    fileSystems = mkPersistentBindMounts (cfg.dirs ++ cfg.files);
    boot.initrd.systemd.services.make-source-of-persistent-dirs = {
      wantedBy = [ "initrd.target" ];
      before = [ "initrd-switch-root.target" ];
      requires = [ "sysroot-persist.mount" ];
      after = [ "sysroot-persist.mount" ];
      serviceConfig.Type = "oneshot";
      unitConfig.DefaultDependencies = false;
      script = mkPersistentSourcePaths cfg.dirs + "\n" + mkPersistentFileSources cfg.files;
    };
  };
}
