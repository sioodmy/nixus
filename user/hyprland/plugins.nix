# Hyprland plugins.
#
# Hyprland plugins are shared objects dlopen'd into the compositor, so they
# have to be compiled against the exact Hyprland headers of the running
# binary. Every derivation here therefore goes through
# `hyprlandPlugins.mkHyprlandPlugin`, which pins `buildInputs` to the same
# `pkgs.hyprland` the compositor itself comes from (see user/hyprland) -- a
# plugin built against any other Hyprland refuses to load on an ABI hash
# mismatch.
#
# Nothing is fetched as a prebuilt .so: those are tied to the upstream release
# commit, not to nixpkgs' Hyprland build, so they drift out of sync the moment
# nixpkgs moves. Building from source costs a compile and is always correct.
#
# Only hypr-dynamic-cursors is packaged upstream; the other two live here.
{ pkgs }:
let
  inherit (pkgs.lib)
    filterAttrs
    licenses
    platforms
    ;

  mk = pkgs.hyprlandPlugins.mkHyprlandPlugin;

  hasFunctionHooks = pkgs.stdenv.hostPlatform.isx86;

  # The loader takes a path, and each derivation installs its plugin as
  # `$out/lib/lib<name>.so`. Wrapping the .so in a passthru attribute keeps the
  # path out of the config template in user/hyprland/default.nix, which only
  # knows plugin names.
  plugin =
    out: name:
    out
    // {
      passthru = out.passthru // {
        pluginPath = "${out}/lib/lib${name}.so";
      };
    };
  # A plugin that cannot run on this architecture is set to null here rather
  # than being wrapped in `lib.optionalAttrs`: assigning the result of
  # optionalAttrs still *creates* the key, with an empty attrset as its value,
  # which then fails the `types.package` check in user/hyprland. The filter at
  # the bottom is what actually drops the key.
  allPlugins = {
    # Shake to find + tilt mode.
    #
    # x86_64 only, and not by choice: the whole plugin is built on Hyprland's
    # function hooks, and CHookSystem::hook() returns false outright on anything
    # but x86_64 (it patches in a `jmp rel32`). The plugin does not degrade --
    # it throws "hooking failed, are you on x86_64?" out of PLUGIN_INIT, so on
    # ARM the load fails and every start ends in an error notification.
    #
    # So it is left out of the plugin set on non-x86_64 rather than loaded and
    # failing. Both features that were asked for (shake to find and tilt) hang off
    # the same hooks, so there is no subset that would work.
    dynamic-cursors =
      if hasFunctionHooks then
        plugin pkgs.hyprlandPlugins.hypr-dynamic-cursors "hypr-dynamic-cursors"
      else
        null;

    # Compositor-level kinetic scrolling, so momentum works in every app instead
    # of only the ones that implement it themselves.
    hypr-kinetic-scroll = plugin (mk {
      pluginName = "hypr-kinetic-scroll";
      version = "0.4.1";

      src = pkgs.fetchFromGitHub {
        owner = "savonovv";
        repo = "hypr-kinetic-scroll";
        rev = "657a8a7cb1cc0a24a06e2dc0947df3e8f4e729ca";
        hash = "sha256-2RI9RSoXhri9tr9DAsB/Zen96DzKsj/wLRbQQKEZ1Yc=";
      };

      nativeBuildInputs = [ pkgs.gnumake ];

      strictDeps = false;
      dontUseCmakeConfigure = true;
      buildFlags = [ "all" ];

      installPhase = ''
        runHook preInstall
        mkdir -p $out/lib
        cp hypr-kinetic-scroll.so $out/lib/libhypr-kinetic-scroll.so
        runHook postInstall
      '';

      meta = {
        description = "Kinetic (inertial) touchpad scrolling for Hyprland";
        homepage = "https://github.com/savonovv/hypr-kinetic-scroll";
        license = licenses.mit;
        platforms = platforms.linux;
      };
    }) "hypr-kinetic-scroll";

    # Forwards pointer motion from the outer gaps and over the shell's bars into
    # the window underneath, so windows can be resized and scrolled without
    # first nudging the cursor past the 5px gap (01-general).
    hypr-edgehover = plugin (mk {
      pluginName = "hypr-edgehover";
      version = "0.1.0";

      src = pkgs.fetchFromGitHub {
        owner = "gfhdhytghd";
        repo = "hypr-edgehover";
        rev = "77b5e1445361b3a1f7b6f03bb4bee15e91229c94";
        hash = "sha256-4yDKWc4fFKxsEk9T9SLhiX3nCWzxG3P1VjznemKu440=";
      };

      nativeBuildInputs = [ pkgs.cmake ];

      # The geometry unit test builds a second binary and only checks arithmetic
      # on constants; skip it.
      cmakeFlags = [ "-DBUILD_TESTING=OFF" ];

      installPhase = ''
        runHook preInstall
        mkdir -p $out/lib
        cp libhypr-edgehover.so $out/lib/
        runHook postInstall
      '';

      meta = {
        description = "Forward edge-gap pointer motion to adjacent Hyprland windows";
        homepage = "https://github.com/gfhdhytghd/hypr-edgehover";
        license = licenses.mit;
        platforms = platforms.linux;
      };
    }) "hypr-edgehover";
  };
in
filterAttrs (_: value: value != null) allPlugins
