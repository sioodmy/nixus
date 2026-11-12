{
  pkgs,
  ...
}:
# Minecraft 1.20.1 bundles its own GLFW 3.4 with the Wayland backend. That
# build aborts window creation with "The platform does not support setting
# the input focus" (Sodium focuses the window right after creating it), so the
# game exits before the main menu.
#
# nixpkgs already ships a Minecraft-patched glfw3-minecraft and puts it on
# LD_LIBRARY_PATH, but LWJGL ignores that: it loads the native library it
# extracted from its own jar first. Point LWJGL at the patched build explicitly.
#
# JDK_JAVA_OPTIONS is used instead of JAVA_TOOL_OPTIONS/_JAVA_OPTIONS because
# Prism deliberately drops those from the environment it hands to the game.
pkgs.symlinkJoin {
  name = "prismlauncher-wrapped";
  paths = [ pkgs.prismlauncher ];
  buildInputs = [ pkgs.makeWrapper ];
  postBuild = ''
    wrapProgram $out/bin/prismlauncher \
      --prefix JDK_JAVA_OPTIONS " " "-Dorg.lwjgl.glfw.libname=${pkgs.glfw3-minecraft}/lib/libglfw.so"
  '';
}
