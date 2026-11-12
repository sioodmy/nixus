{
  pkgs,
  inputs,
  ...
}:
let
  inherit (builtins) attrValues;

  # ArtCraft: gotowe AppImage'e (aarch64 + x86_64), żeby nie kompilować
  # Rusta ze źródeł.
  craftApps = pkgs.callPackage ./artcraft { };
in
{
  environment.systemPackages =
    attrValues {
      prismlauncher = pkgs.callPackage ./wrapped/prismlauncher { };

      inherit (pkgs)
        android-tools
        deluge
        clang-tools
        # t3code idzie przez ./t3code (wrapper z CA bundle na Antigravity 502)
        tesseract
        ffmpegthumbnailer
        brightnessctl
        yt-dlp
        cava
        btop
        mpv
        gh
        antigravity-cli
        antigravity-acp
        libnotify
        wlsunset
        poppler-utils
        #code-cursor
        cursor-cli

        rink
        thunderbird
        jdk17
        jre21_minimal
        rust-analyzer
        bear
        pastel
        nixfmt
        nixfmt-tree
        yazi
        alejandra
        pandoc
        texliveMedium
        vscode-langservers-extracted
        typst
        texlab
        powershell
        # Compositor comes from the hyprland module (user/hyprland).
        geteduroam-cli
        ttyper
        pwvucontrol
        grim
        cliphist
        slurp
        wl-clipboard
        wf-recorder
        rnote
        swaybg
        transmission_4-gtk
        nicotine-plus
        imv
        signal-desktop
        gimp3
        inkscape
        kpcli
        clang
        gnumake
        cargo
        go
        gcc
        git
        ripgrep
        zoxide
        fzf
        eza
        gping
        onefetch
        cpufetch
        microfetch
        tealdeer
        glow
        hyperfine
        imagemagick
        # ffmpeg-full
        nmap
        xh
        grex
        jq
        rsync
        figlet
        qrencode
        unzip
        ;
      inherit (inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system})
        opencode2
        ;
      # tectonic 0.17 pulls rustls/aws-lc-rs; aws-lc-sys builds in system
      # mode (AWS_LC_SYS_USE_SYSTEM=1) but the nixpkgs derivation doesn't
      # list aws-lc in buildInputs, so from-source builds panic with
      # "requires a system-installed AWS-LC". TODO: drop when nixpkgs
      # fixes the package.
      tectonic-unwrapped = pkgs.tectonic-unwrapped.overrideAttrs (old: {
        buildInputs = (old.buildInputs or [ ]) ++ [ pkgs.aws-lc ];
      });
      inherit (inputs.vim.packages.${pkgs.stdenv.hostPlatform.system})
        default
        ;
    }
    ++ [ inputs.helium-browser.packages.${pkgs.stdenv.hostPlatform.system}.default ]
    ++ [
      (pkgs.callPackage ./smath { inherit inputs; })
      (pkgs.callPackage ./symbolical { })
      (pkgs.callPackage ./keepassxc { })
    ]
    ++ [
      craftApps.vectorcraft
      craftApps.figcraft
      craftApps.photocraft
    ];

}
