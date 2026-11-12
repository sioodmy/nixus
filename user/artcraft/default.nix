{
  pkgs,
  lib,
  appimageTools,
  fetchurl,
}:

let
  arch = if pkgs.stdenv.hostPlatform.isAarch64 then "aarch64" else "x86_64";

  # ArtCraft nie ma swoich appek w nixpkgs, a kompilacja Rusta na aarch64 to
  # godziny. Upstream publikuje gotowe AppImage'e dla obu architektur, więc
  # bierzemy je stąd: fetchurl tylko ściąga, reszta to rozpakowanie squashfs
  # i opakowanie w FHS env (ten sam wzorzec co user/smath).
  mkCraftApp =
    {
      pname,
      version,
      description,
      hashes,
      homepage ? "https://getartcraft.com/apps/${pname}",
    }:
    let
      src = fetchurl {
        url = "https://github.com/storytold/${pname}/releases/download/v${version}/${pname}-${version}-linux-${arch}.AppImage";
        hash = hashes.${arch};
      };

      contents = appimageTools.extract { inherit pname version src; };

      desktopId = "ai.storyteller.${pname}";
    in
    appimageTools.wrapType2 {
      inherit pname version src;

      extraInstallCommands = ''
                mkdir -p $out/share/applications $out/share/metainfo $out/share/mime/packages
                install -m444 ${contents}/usr/share/applications/${desktopId}.desktop \
                  $out/share/applications/${desktopId}.desktop
                install -m444 ${contents}/usr/share/metainfo/${desktopId}.metainfo.xml \
                  $out/share/metainfo/${desktopId}.metainfo.xml
                install -m444 ${contents}/usr/share/mime/packages/${desktopId}.xml \
                  $out/share/mime/packages/${desktopId}.xml
                cp -r ${contents}/usr/share/icons $out/share/

                if [ -f "${contents}/usr/bin/${pname}-cli" ]; then
                  cat > "$out/bin/${pname}-cli" << 'EOF'
        #!/bin/sh
        exec "$0/../${pname}" cli "$@"
        EOF
                  chmod +x "$out/bin/${pname}-cli"
                fi

                if [ "${pname}" = "figcraft" ]; then
                  cat > "$out/bin/figcraft-mcp" << 'EOF'
        #!/bin/sh
        PORT="''${FIGCRAFT_PORT:-19999}"
        if (echo > /dev/tcp/127.0.0.1/"$PORT") 2>/dev/null; then
          exec "$0/../figcraft" cli mcp --attach "$PORT" "$@"
        else
          exec "$0/../figcraft" cli mcp "$@"
        fi
        EOF
                  chmod +x "$out/bin/figcraft-mcp"
                fi
      '';

      meta = {
        inherit description homepage;
        license = with lib.licenses; [
          mit
          asl20
        ];
        mainProgram = pname;
        platforms = [
          "aarch64-linux"
          "x86_64-linux"
        ];
      };
    };
in
{
  vectorcraft = mkCraftApp {
    pname = "vectorcraft";
    version = "0.18.0";
    description = "Open-source vector illustration app with SVG and PDF support, written in Rust";
    hashes = {
      aarch64 = "sha256-QxKRfcBwTYln0cPTf8OFTVrhNWMcF7tMy4EawTc6st8=";
      x86_64 = "sha256-ng1If8cbEi6W8ZsTbTrNs4XqpAn21KgDRVfyNWLyEIo=";
    };
  };

  figcraft = mkCraftApp {
    pname = "figcraft";
    version = "0.12.1";
    description = "Open-source interface design and prototyping app, written in Rust";
    hashes = {
      aarch64 = "sha256-N2v+/m5ZZ3UofKKd8eQ31DiR2VRVmltu03LmDPKP+mA=";
      x86_64 = "sha256-xSvgRte+pzeQ81hP/KbseTXfIprc6Pjkg7AyQu4qqx8=";
    };
  };

  photocraft = mkCraftApp {
    pname = "photocraft";
    version = "0.17.0";
    description = "Open-source photo editor with layered PSD support, written in Rust";
    hashes = {
      aarch64 = "sha256-j28026GmiAKhVBORctgOajEHWaeKdfAtOdWybM8zhOs=";
      x86_64 = "sha256-zncpnyQ1NKwdJIqoHJqf0niuQHwCTLkx4Dkx63C+VK8=";
    };
  };
}
