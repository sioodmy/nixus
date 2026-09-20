{
  pkgs,
  inputs,
  ...
}:
let
  inherit (builtins) attrValues;
in
{
  environment.systemPackages =
    attrValues {
      inherit (pkgs)
        deluge
        clang-tools
        tesseract
        ffmpegthumbnailer
        brightnessctl
        yt-dlp
        cava
        bottom
        #mpv
        antigravity-cli
        libnotify
        wlsunset
        poppler-utils
        #code-cursor
        opencode
        rink
        thunderbird
        jdk17
        jre21_minimal
        rust-analyzer
        firefox-devedition
        bear
        ferdium
        pastel
        nixfmt
        nixfmt-tree
        yazi
        alejandra
        pandoc
        texliveMedium
        vscode-langservers-extracted
        tectonic-unwrapped
        typst
        texlab
        powershell
        niri
        geteduroam-cli
        ttyper
        pwvucontrol
        grim
        cliphist
        slurp
        wl-clipboard
        flare-signal
        wf-recorder
        rnote
        swaybg
        transmission_4-gtk
        nicotine-plus
        imv
        signal-desktop
        gimp3
        inkscape
        keepassxc
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
      inherit (inputs.backendqs.packages.${pkgs.stdenv.hostPlatform.system})
        leninshell
        ;
      inherit (inputs.helix.packages.${pkgs.stdenv.hostPlatform.system})
        helix
        ;
    }
    ++ [ inputs.helium-browser.packages.${pkgs.stdenv.hostPlatform.system}.default ]
    ++ [ inputs.backendqs.packages.${pkgs.stdenv.hostPlatform.system}.default ];

}
