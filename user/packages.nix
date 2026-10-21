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
        prismlauncher
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
        # Compositor comes from the hyprland module (user/hyprland).
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
      inherit (inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system})
        opencode2
        codex
        ;
      inherit (inputs.vim.packages.${pkgs.stdenv.hostPlatform.system})
        default
        ;
    }
    ++ [ inputs.helium-browser.packages.${pkgs.stdenv.hostPlatform.system}.default ]
    ++ [ inputs.backendqs.packages.${pkgs.stdenv.hostPlatform.system}.default ]
    ++ [ (pkgs.callPackage ./smath { inherit inputs; }) ];

}
