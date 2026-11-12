{
  lib,
  stdenv,
  fetchFromGitHub,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  patch,
  python314,
  vulkan-loader,
  mesa,
  gfortran,
  zlib,
}:
let
  # v0.7.41 is the release the wheel, the hash-locked vendor wheel set and
  # this source tree all belong to; upstream does not support mixing them.
  version = "0.7.41";
  mlxVersion = "0.32.4.dev202611111431+8380f002";
  wheelName = "mlx_omarchy-${mlxVersion}-cp314-cp314-linux_aarch64.whl";

  # The cp314 aarch64 wheel: GPU kernels, the bundled OpenBLAS and the
  # (M1-unsupported here, GPU-only install) ANE assets.
  wheel = fetchurl {
    url = "https://github.com/joshuaswarren/omarchy-mlx/releases/download/v${version}/${
      builtins.replaceStrings [ "+" ] [ "%2B" ] wheelName
    }";
    sha256 = "d2f21fe1a460e94d8a371dc8277b740b055f7c3a073775fddab83fd8182680c8";
    name = wheelName;
  };

  # The release's hash-locked wheel set; pip verifies every artifact
  # (the mlx-omarchy wheel included) against requirements-lock.txt.
  vendor = fetchurl {
    url = "https://github.com/joshuaswarren/omarchy-mlx/releases/download/v${version}/omarchy-mlx-vendor-wheels-v${version}-cp314-aarch64.tar";
    sha256 = "bcffb15979dcb9fad0c43920af00de55b38c0bc584a7a11160bbdd618a514e22";
  };
in
stdenv.mkDerivation {
  pname = "mlx-omarchy";
  inherit version;

  # Serve CLI, Laya/Bonsai2 servers, the MLX Chat assistant and the vendored
  # mlx-lm patch series, all from the same release as the wheel.
  src = fetchFromGitHub {
    owner = "joshuaswarren";
    repo = "omarchy-mlx";
    rev = "8380f0020708d1b14c1a7e5ff912fd2a8134be08"; # v0.7.41
    hash = "sha256-V0c8DIsbv0Gu6sE6EYbETi31xxhdWZirW5Y3kSEYnnE=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    patch # the mlx-lm serve patch series applies with patch(1)
    python314
  ];

  buildInputs = [
    # The wheel bundles its own OpenBLAS, but that still needs
    # libgfortran/libgomp, and libmlx needs libstdc++/libgcc_s. numpy's
    # bundled libgfortran additionally links zlib.
    gfortran.cc.lib
    zlib
  ];

  buildPhase = ''
    runHook preBuild

    # Upstream system layout ($SYSTEM_PREFIX = /usr/lib/omarchy-mlx): a
    # private venv plus the packaged Vulkan ICD slot, so the runtime's own
    # venv and ICD discovery find everything without extra environment.
    VENV=$out/lib/omarchy-mlx/venv
    mkdir -p $out/lib/omarchy-mlx
    PYTHONNOUSERSITE=1 ${python314}/bin/python3 -m venv "$VENV"

    wheelhouse=$(mktemp -d)
    tar -xf ${vendor} -C "$wheelhouse" --strip-components=1
    cp ${wheel} "$wheelhouse/${wheelName}"
    "$VENV/bin/python" -m pip install --no-index --find-links "$wheelhouse" \
      --require-hashes -r "$wheelhouse/requirements-lock.txt"

    # The vendored mlx-lm serve patches (GDN fast routes, greedy vocab
    # prune...); the patches/ series matches the locked mlx-lm 0.31.3.
    MLX_OMARCHY_CONV_RING=0 bash scripts/apply-mlx-lm-patches.sh "$VENV"

    # The serve CLI, the Laya and Bonsai2 servers and the MLX Chat
    # assistant ship as plain sources in the release tree; the system
    # install puts them next to the wheel in site-packages.
    site="$VENV/lib/python3.14/site-packages"
    for pkg in mlx_omarchy_serve mlx_omarchy_laya mlx_omarchy_bonsai2 mlx_omarchy_assistant; do
      cp -a "serve/$pkg" "$site/"
    done
    cp serve/mlx_omarchy_paths.py "$site/"

    # Terminal face of MLX Chat.
    install -Dm644 demo/chat.py $out/lib/omarchy-mlx/chat.py

    # Same staged-asset check the upstream packaging runs before shipping.
    "$VENV/bin/python" scripts/verify_runtime_assets.py \
      "$site/mlx/share/mlx-omarchy/parakeet-1"

    # The backend refuses to run without a Honeykrisp ICD it can select,
    # and it only looks at $OMARCHY_MLX_SYSTEM_PREFIX/vulkan/ (plus the
    # Arch-only /usr/... paths). Point that slot at nixpkgs' own Mesa
    # Asahi ICD — the same Mesa build the system graphics stack uses.
    mkdir -p $out/lib/omarchy-mlx/vulkan
    cp ${mesa}/share/vulkan/icd.d/asahi_icd.aarch64.json \
      $out/lib/omarchy-mlx/vulkan/honeykrisp_icd.aarch64.json

    runHook postBuild
  '';

  preFixup = ''
    # Wheels bundle their heavy native deps beside themselves (mlx/lib,
    # numpy.libs, soundfile's _soundfile_data, ...); let autoPatchelf
    # resolve those DT_NEEDED instead of failing on them.
    addAutoPatchelfSearchPath "$out/lib/omarchy-mlx/venv/lib/python3.14/site-packages"
  '';

  postFixup = ''
        VENV=$out/lib/omarchy-mlx/venv
        MLXBIN=$VENV/lib/python3.14/site-packages/mlx/bin
        mkdir -p $out/bin

        # libmlx dlopen()s libvulkan.so.1 (not DT_NEEDED, so autoPatchelf
        # cannot wire it): the nixpkgs loader comes through LD_LIBRARY_PATH,
        # and the loader then reads the packaged Mesa ICD json above.
        wrapEnv=(
          --prefix LD_LIBRARY_PATH : ${vulkan-loader}/lib
          --set OMARCHY_MLX_VENV "$VENV"
          --set OMARCHY_MLX_SYSTEM_PREFIX "$out/lib/omarchy-mlx"
        )

        # "Use in your scripts": a Python interpreter with mlx-omarchy and
        # mlx-lm installed (import mlx.core as mx).
        makeWrapper "$VENV/bin/python" $out/bin/mlx-omarchy "''${wrapEnv[@]}"

        # MLX Chat: the local web application.
        makeWrapper "$VENV/bin/python" $out/bin/mlx-omarchy-chat \
          "''${wrapEnv[@]}" --add-flags "-m mlx_omarchy_assistant"

        # Terminal chat; same shared coordinator as the web application.
        makeWrapper "$VENV/bin/python" $out/bin/mlx-omarchy-demo \
          "''${wrapEnv[@]}" --add-flags "$out/lib/omarchy-mlx/chat.py"

        # Serve CLI: catalog/plan/serve, memory admission, approve-first
        # model downloads.
        makeWrapper "$VENV/bin/python" $out/bin/mlx-omarchy-serve \
          "''${wrapEnv[@]}" --add-flags "-m mlx_omarchy_serve"

        # GPU and driver state probe (an ELF from the wheel; autoPatchelf set
        # its interpreter and rpath).
        makeWrapper "$MLXBIN/mlx-omarchy-info" $out/bin/mlx-omarchy-info "''${wrapEnv[@]}"

        # Parakeet STT CLI; a data-file python script, so run it through the
        # venv interpreter to get its vendored numpy/protobuf.
        makeWrapper "$VENV/bin/python" $out/bin/mlx-omarchy-parakeet \
          "''${wrapEnv[@]}" --add-flags "$MLXBIN/mlx-omarchy-parakeet"

        # Launcher menu entry.
        mkdir -p $out/share/applications
        cat >$out/share/applications/mlx-omarchy-chat.desktop <<EOF
    [Desktop Entry]
    Type=Application
    Name=MLX Chat (Apple GPU)
    Comment=Local chat and typed decisions on the Apple GPU via mlx-omarchy
    Exec=$out/bin/mlx-omarchy-chat
    Icon=applications-internet
    Categories=Development;Utility;
    EOF

        # PM-QoS CPU latency hold while GPU work is in flight (~1% decode on
        # the M1); picked up through services.udev.packages.
        install -Dm644 $src/packaging/udev/70-omarchy-mlx-cpu-dma-latency.rules \
          $out/lib/udev/rules.d/70-omarchy-mlx-cpu-dma-latency.rules
  '';

  meta = {
    description = "MLX-compatible Vulkan and ANE backends for Apple Silicon running Linux";
    homepage = "https://github.com/joshuaswarren/omarchy-mlx";
    license = lib.licenses.mit;
    platforms = [ "aarch64-linux" ];
    mainProgram = "mlx-omarchy";
  };
}
