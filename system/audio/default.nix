{ pkgs, ... }:
{
  services.playerctld.enable = true;
  services.pipewire = {
    enable = true;
    alsa = {
      enable = true;
      support32Bit = true;
    };
    wireplumber = {
      enable = true;
      extraConfig = {
        "10-bluez" = {
          "monitor.bluez.properties" = {
            "bluez5.enable-sbc-xq" = true;
            "bluez5.enable-msbc" = true;
            "bluez5.enable-hw-volume" = true;
            "bluez5.a2dp.ldac.quality" = "sq";
            "bluez5.codecs" = [
              "sbc"
              "sbc_xq"
              "aac"
              "ldac"
              "aptx"
              "aptx_hd"
            ];
          };
        };
      };
    };
    pulse.enable = true;
  };

  programs.noisetorch.enable = true;
  hardware = {

    bluetooth = {
      enable = true;
      powerOnBoot = true;
      package = pkgs.bluez5-experimental;
      settings = {
        General = {
          ControllerMode = "bredr";

          Enable = "Source,Sink,Media,Socket";
        };
      };
    };
  };
}
