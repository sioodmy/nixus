{
  pkgs,
  ...
}:
{
  environment.systemPackages = builtins.attrValues {
    inherit (pkgs)
      nvfetcher

      nix-eval-jobs
      nix-fast-build
      ;
  };
  documentation = {
    enable = false;
    man.enable = false;
    dev.enable = false;
    info.enable = false;
    nixos.enable = false;
  };
  nix = {
    # gc kills ssds
    gc.automatic = false;

    # nix but cooler
    package = pkgs.lixPackageSets.stable.lix;

    # Make builds run with low priority so my system stays responsive
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";

    settings = {
      flake-registry = "/etc/nix/registry.json";
      auto-optimise-store = true;
      # use binary cache, its not gentoo
      builders-use-substitutes = true;
      # allow sudo users to mark the following values as trusted
      allowed-users = [ "@wheel" ];
      trusted-users = [
        "root"
        "sioodmy"
      ];
      commit-lockfile-summary = "chore: Update flake.lock";
      accept-flake-config = true;
      keep-derivations = true;
      keep-outputs = true;
      warn-dirty = false;
      use-xdg-base-directories = true;

      sandbox = true;
      max-jobs = 2;
      # continue building derivations if one fails
      keep-going = true;
      log-lines = 20;
      extra-experimental-features = [
        "flakes"
        "nix-command"
        "pipe-operator"
      ];

      # use binary cache, its not gentoo
      substituters = [
        "https://cache.nixos.org"
        "https://nixos-apple-silicon.cachix.org"
      ];

      trusted-public-keys = [
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
        "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
      ];
    };
  };

  # Włączone: runtime t3code pod ~/.t3 to zwykłe drzewo npm, więc binarki
  # providerów (m.in. Antigravity ACP) potrzebują loadera Niksa także poza
  # shellem logowania. Bez tego systemd unit t3code nie widzi glibc.
  #
  # T3 dociąga też własny `chrome-headless-shell` (Playwright) do
  # ~/.t3/tools. To obcy binarny blob bez RPATH-a, a na NixOS nie ma apt-get,
  # więc `t3 browser setup` nie ma skąd wziąć bibliotek. Lista poniżej to
  # bezpośrednie NEEDED tego binarium (na podstawie RUNPATH z nixpkgsowego
  # chromium); ich zależności rozwiązują się już przez własne RUNPATH-y.
  programs.nix-ld = {
    enable = true;
    libraries = with pkgs; [
      alsa-lib
      at-spi2-core
      cairo
      cups
      dbus
      expat
      flac
      glib
      libffi
      libgbm
      libglvnd
      libjpeg
      libpulseaudio
      libX11
      libxcb
      libXcomposite
      libXdamage
      libXext
      libXfixes
      libxkbcommon
      libXrandr
      libxml2
      libxslt
      nspr
      nss
      pango
      pciutils
      systemd
      vulkan-loader
    ];
  };

  programs.nh = {
    enable = true;
    flake = "/home/sioodmy/dev/dotfiles";
  };

  # WE DONT WANT TO BUILD STUFF ON TMPFS
  # ITS NOT A GOOD IDEA
  systemd.services.nix-daemon = {
    environment.TMPDIR = "/var/tmp";
  };

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = true;
    };
  };
}
