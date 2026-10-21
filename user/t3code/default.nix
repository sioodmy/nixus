{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  # Zaczerpnięte z https://github.com/GrajAP/nixos_config/tree/dcbf6bb5cb701427182892bdebfe7beaf812ff46/apps/t3code
  #
  # Dlaczego Antigravity padał z `502 Bad Gateway`:
  # ACP Antigravity wozi własnego Pythona + OpenSSL. Na NixOS domyślny bundle
  # (/etc/ssl) nie jest widoczny dla procesów startowanych przez t3code,
  # więc każdy request do Gemini kończył się na
  # `SSL: CERTIFICATE_VERIFY_FAILED`, co ACP raportuje jako 502.
  # Lek: jawnie wskazać bundle ze sklepu Niksa każdemu binowi t3code
  # (tak samo robi wrapper GrajAPa przez SSL_CERT_FILE i spółkę).
  certBundle = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

  # T3 Connect tuneluje przez cloudflared; t3code z llm-agents.nix też go
  # nie dokłada do PATH, więc dokładamy go wrapperem (jak providerPath u GrajAPa).
  providerPath = lib.makeBinPath [
    pkgs.cloudflared
    pkgs.gh
    pkgs.git
  ];

  # t3code bierzemy z tego samego flake co opencode (numtide/llm-agents.nix),
  # a nie z nixpkgs. Pakiet ma dwa outputy: `out` (CLI `t3`) i `desktop`
  # (`t3code-desktop`) -- bierzemy oba, żeby mieć i CLI, i desktop.
  llm-agents = inputs.llm-agents.packages.${pkgs.stdenv.hostPlatform.system};

  # `providerPackages` steruje tylko PATH-em wrappera, a Nix nie forsuje
  # nieużywanych argumentów funkcji -- więc claude-code i codex (których nie
  # używamy) nie trafiają w ogóle do buildu, mimo że upstream wpina je z defaultu.
  t3code = llm-agents.t3code.override {
    providerPackages = [
      llm-agents.opencode
      llm-agents.cursor-agent
      llm-agents.grok
    ];
  };

  t3code-wrapped = pkgs.symlinkJoin {
    name = "t3code-${t3code.version}-with-ca";
    paths = [
      t3code
      t3code.desktop
    ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      for program in "$out"/bin/*; do
        wrapProgram "$program" \
          --prefix PATH : "${providerPath}" \
          --set T3CODE_DISABLE_AUTO_UPDATE "1" \
          --set T3CODE_CLOUDFLARED_PATH "${lib.getExe pkgs.cloudflared}" \
          --set SSL_CERT_FILE "${certBundle}" \
          --set NIX_SSL_CERT_FILE "${certBundle}" \
          --set NODE_EXTRA_CA_CERTS "${certBundle}" \
          --set REQUESTS_CA_BUNDLE "${certBundle}" \
          --set CURL_CA_BUNDLE "${certBundle}"
      done
    '';
  };

  # Mostek Antigravity dla 16K-page ARM (pandora / Apple Silicon).
  #
  # Dwa niezależne powody, dla których ACP nie działa tu natywnie:
  # 1. Google wozi agy_acp_server.par jako binarkę x86_64 na strony 4K
  #    z twardym checkiem przy starcie
  #    (`sysconf(_SC_PAGE_SIZE) == 4096`, inaczej SIGABRT), a kernel
  #    nixos-apple-silicon jest tylko 16K ("The 4K patch no longer
  #    applies so this kernel only operates in 16K mode").
  # 2. Nixpkgsowy antigravity-acp 1.1.1 dla aarch64 ma ucięty runtime
  #    (678 MB zamiast 1862 MB upstream; nagłówki sekcji ELF za EOF,
  #    `RuntimeError: Section not found: .par_data`).
  #
  # Lek: oficjalny runtime x86_64 1.1.1 (te same bajty, które T3 0.0.40
  # pobrałby sobie sam -- hash zgodny z jego manifestem) puszczony przez
  # qemu-user (binfmt) z sysrootem glibc x86_64. Handshake ACP `initialize`
  # przechodzi w ~22 s, budżet health checka T3 to 90 s.
  # Na hostach x86_64 (calypso) mostek jest zbędny.
  # W T3: Settings -> Providers -> Antigravity -> Binary path =
  #   /run/current-system/sw/bin/agy_acp_server-qemu
  #
  # HYBRYDA (fix na `found bad pointer in Go heap` przy modelu 3.8 high):
  # agy_acp_server.par (Python) idzie przez qemu-user -- to działa stabilnie.
  # Ale localharness_external (statyczny Go) NIE idzie przez qemu: Go +
  # qemu-user sypie `fatal error: found bad pointer in Go heap (incorrect
  # use of unsafe or cgo?)` i zrywa sesję (WS close 1006) na cięższych
  # runach agenta. Statyczny Go działa natywnie na 16K pages, więc bierzemy
  # harness z oficjalnego zipa arm64 (ten sam release 1.1.1, bajt w bajt
  # jak u Google, bez patchelf/strip) i kładziemy go obok .par -- .par
  # spawnuje siblinga, binfmt nie dotyka natywnego ELF-a. Wrapper dokłada
  # jeszcze GODEBUG=asyncpreemptoff=1 / GOMAXPROCS=1 / QEMU_STACK_SIZE na
  # wypadek resztek x86_64-Go pod qemu.
  isAarch64 = pkgs.stdenv.hostPlatform.system == "aarch64-linux";

  pkgsX64 = inputs.nixpkgs.legacyPackages."x86_64-linux";

  antigravityBridge = pkgs.stdenvNoCC.mkDerivation {
    pname = "antigravity-qemu-bridge";
    version = "1.1.1";
    srcX64 = pkgs.fetchurl {
      url = "https://dl.google.com/agy-extensions/releases/linux/agy-acp-server-agy_acp_server_1.1.1-linux-x86_64.zip";
      hash = "sha256-OPYtAbMt6wkHs9OacewwH9Njafb/0c8mLUrzhRd/ed8=";
    };
    srcArm = pkgs.fetchurl {
      url = "https://dl.google.com/agy-extensions/releases/linux/agy-acp-server-agy_acp_server_1.1.1-linux-arm64.zip";
      hash = "sha256-7WnmSzCPyxI6tUvzJ3v5yw1lEGT4hepaqw/1IMcXU5g=";
    };
    nativeBuildInputs = [ pkgs.unzip ];
    # Obcoarchitekturowe bloby mają zostać bajt w bajt jak u Google.
    # Żadnego strip/patchelf (to prawdopodobnie skasowało build arm64).
    dontFixup = true;
    dontUnpack = true;
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/x86_64-sysroot/lib64 $out/x86_64-sysroot/lib
      unzip -p "$srcX64" agy_acp_server.par > $out/bin/agy_acp_server.par
      chmod 755 $out/bin/agy_acp_server.par
      # Natywny harness Go (aarch64, static) -- omija qemu-user.
      unzip -p "$srcArm" localharness_external > $out/bin/localharness_external
      chmod 755 $out/bin/localharness_external
      ln -s ${pkgsX64.glibc}/lib/* $out/x86_64-sysroot/lib64/
      ln -s ${pkgsX64.glibc}/lib/* $out/x86_64-sysroot/lib/
      substitute ${./agy-qemu-wrapper.sh} $out/bin/agy_acp_server-qemu \
        --replace-fail @OUT@ "$out" \
        --replace-fail @CACERT@ "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
      chmod 755 $out/bin/agy_acp_server-qemu
      runHook postInstall
    '';
  };
in
{
  # Wrapper niesie CA bundle, ale procesy odpalone poza nim (serwer
  # `t3 service`, ACP startowany z systemd) muszą go dostać inaczej.
  environment.sessionVariables = {
    SSL_CERT_FILE = certBundle;
    NIX_SSL_CERT_FILE = certBundle;
  };

  environment.systemPackages = [
    t3code-wrapped
    pkgs.cloudflared
  ]
  ++ lib.optionals isAarch64 [ antigravityBridge ];

  # Runtime pod ~/.t3 to zwykłe drzewo npm, więc binarki providerów są
  # dynamicznie linkowane i potrzebują loadera Niksa także poza shellem
  # logowania (goły programs.nix-ld pokrywa tylko shell).
  systemd.user.services.t3code = {
    overrideStrategy = "asDropin";
    serviceConfig = {
      Environment = [
        "PATH=%h/.local/share/t3code/npm/bin:%h/.npm-global/bin:/run/wrappers/bin:/run/current-system/sw/bin:/etc/profiles/per-user/%U/bin:%h/.local/state/nix/profile/bin:%h/.nix-profile/bin"
        "T3CODE_CLOUDFLARED_PATH=${lib.getExe pkgs.cloudflared}"
        "NIX_LD=/run/current-system/sw/share/nix-ld/lib/ld.so"
        "NIX_LD_LIBRARY_PATH=/run/current-system/sw/share/nix-ld/lib"
        "SSL_CERT_FILE=${certBundle}"
        "SSL_CERT_DIR=${pkgs.cacert}/etc/ssl/certs"
        "NIX_SSL_CERT_FILE=${certBundle}"
        "NODE_EXTRA_CA_CERTS=${certBundle}"
        "REQUESTS_CA_BUNDLE=${certBundle}"
        "CURL_CA_BUNDLE=${certBundle}"
      ];
    };
  };
}
