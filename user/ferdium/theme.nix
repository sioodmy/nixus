{
  pkgs,
  ...
}:
let
  palette = builtins.fromJSON (builtins.readFile ../quickshell/ui/palette.json);
  replacements = with palette; {
    "#11111b" = background;
    "#181825" = background;
    "#1e1e2e" = surface;
    "#313244" = raised;
    "#45475a" = edge;
    "#585b70" = edge;
    "#6c7086" = muted;
    "#7f849c" = muted;
    "#9399b2" = muted;
    "#a6adc8" = muted;
    "#bac2de" = highlight;
    "#cdd6f4" = text;
    "#89b4fa" = accent;
    "#cba6f7" = accent;
    "#a6e3a1" = green;
    "#f38ba8" = red;
    "#f9e2af" = yellow;
    "#fab387" = yellow;
    "#89dceb" = cyan;
    "#94e2d5" = cyan;
  };
  themedCss =
    file:
    pkgs.writeText (builtins.baseNameOf file) (
      pkgs.lib.replaceStrings (builtins.attrNames replacements) (builtins.attrValues replacements) (
        builtins.readFile file
      )
    );
  jq = "${pkgs.jq}/bin/jq";
  aeroCss =
    file:
    pkgs.writeText (builtins.baseNameOf file) (
      pkgs.lib.replaceStrings (map (name: "@${pkgs.lib.toUpper name}@") (builtins.attrNames palette))
        (builtins.attrValues palette)
        (builtins.readFile ./aero-common.css + "\n" + builtins.readFile file)
    );
  appCss = aeroCss ./aero-app.css;
  messengerCss = aeroCss ./aero-messenger.css;
  whatsappCss = aeroCss ./aero-whatsapp.css;
  discordDarkmodeCss = aeroCss ./aero-discord.css;
  discordWebviewJs = ./ferdium-discord-webview.js;
  discordIndexJs = ./ferdium-discord-index.js;
  discordNotificationCompatJs = ./ferdium-discord-notification-compatibility.js;
  gmailDarkmodeCss = themedCss ./ferdium-gmail-darkmode.css;
  whatsappDarkmodeCss = whatsappCss;
  protonMailDarkmodeCss = themedCss ./ferdium-proton-mail-darkmode.css;
  instagramDarkmodeCss = themedCss ./ferdium-instagram-darkmode.css;

  ferdiumCatppuccinScript = pkgs.writeShellScript "ferdium-aero-setup" ''
        set -eu
        export PATH=${
          pkgs.lib.makeBinPath [
            pkgs.coreutils
            pkgs.gnused
            pkgs.gnugrep
            pkgs.jq
            pkgs.util-linux
          ]
        }:$PATH
        ferdium_dir="''${FERDIUM_AERO_DATA_DIR:-''${XDG_CONFIG_HOME:-$HOME/.config}/Ferdium}"
        recipes_dir="$ferdium_dir/recipes"
        mkdir -p "$ferdium_dir/config" "$recipes_dir"
        exec 9>"$ferdium_dir/.aero-setup.lock"
        flock 9
        install_css() {
          src="$1"
          dst="$2"
          if [ -f "$dst" ] && [ ! -e "$dst.pre-aero.bak" ]; then
            cp -L "$dst" "$dst.pre-aero.bak"
          fi
          tmp_css=$(mktemp "$(dirname "$dst")/.aero-css.XXXXXX")
          cat "$src" > "$tmp_css"
          chmod 644 "$tmp_css"
          mv -f "$tmp_css" "$dst"
        }
        pin_recipe() {
          recipe_json="$1"
          tmp_recipe=$(mktemp "$(dirname "$recipe_json")/.aero-recipe.XXXXXX")
          ${jq} '.version = "999.999.999"' "$recipe_json" > "$tmp_recipe"
          chmod 644 "$tmp_recipe"
          mv -f "$tmp_recipe" "$recipe_json"
        }
        install_css ${appCss} "$ferdium_dir/config/custom.css"

        # 1. Setup Discord recipe with persistent theme & version pinning
        discord_dir="$recipes_dir/discord"
        mkdir -p "$discord_dir"

        # Apply Aero independently of the service's native theme preference.
        install_css "${discordDarkmodeCss}" "$discord_dir/service.css"
        install_css "${discordDarkmodeCss}" "$discord_dir/darkmode.css"
        install_css "${discordDarkmodeCss}" "$discord_dir/user.css"

        # Copy persistent webview and index scripts
        cp -f "${discordWebviewJs}" "$discord_dir/webview.js"
        cp -f "${discordIndexJs}" "$discord_dir/index.js"
        cp -f "${discordNotificationCompatJs}" "$discord_dir/notification-compatibility.js"

        # Write user.js for DOM readiness fallback
        cat << 'EOF' > "$discord_dir/user.js"
    module.exports = (config, userScript) => {
      const ensureClasses = () => {
        try {
          const targets = [document.documentElement, document.body, document.getElementById('app-mount')];
          for (const el of targets) {
            if (el) {
              if (!el.classList.contains('visual-refresh')) el.classList.add('visual-refresh');
              if (!el.classList.contains('theme-dark')) el.classList.add('theme-dark');
              el.setAttribute('data-theme', 'dark');
            }
          }
        } catch (_) {}
      };
      ensureClasses();
      if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', ensureClasses);
      }
      window.addEventListener('load', ensureClasses);
    };
    EOF

        # Write package.json with version 999.999.999 to prevent Ferdium recipe auto-updater from overwriting it
        cat << 'EOF' > "$discord_dir/package.json"
    {
      "id": "discord",
      "name": "Discord",
      "version": "999.999.999",
      "license": "MIT",
      "config": {
        "serviceURL": "https://discord.com/app",
        "hasNotificationSound": true,
        "hasIndirectMessages": true
      },
      "defaultIcon": "https://cdn.jsdelivr.net/gh/ferdium/ferdium-recipes@main/recipes/discord/icon.svg"
    }
    EOF

        # 2. Setup Gmail recipe with persistent Catppuccin theme & version pinning
        gmail_dir="$recipes_dir/gmail"
        if [ -f "$gmail_dir/package.json" ]; then
          cp -f "${gmailDarkmodeCss}" "$gmail_dir/darkmode.css"
          cp -f "${gmailDarkmodeCss}" "$gmail_dir/service.css"
          pin_recipe "$gmail_dir/package.json"
        fi

        # 3. Setup WhatsApp recipe with persistent Catppuccin theme & version pinning.
        # The stock darkmode.css is an outdated Franz-era stylesheet that no longer
        # matches web.whatsapp.com, and the recipe auto-updater wipes custom files.
        whatsapp_dir="$recipes_dir/whatsapp"
        if [ -f "$whatsapp_dir/package.json" ]; then
          install_css "${whatsappDarkmodeCss}" "$whatsapp_dir/darkmode.css"
          install_css "${whatsappDarkmodeCss}" "$whatsapp_dir/service.css"

          # Pin the version so the auto-updater stops overwriting the theme.
          # NOTE: this also freezes webview.js badge-selector updates; unpin
          # (delete the dir, restart Ferdium) if unread badges ever go stale.
          pin_recipe "$whatsapp_dir/package.json"
        fi

        # 4. Setup Proton Mail recipe with Catppuccin theme & version pinning
        proton_dir="$recipes_dir/proton-mail"
        if [ -f "$proton_dir/package.json" ]; then
          cp -f "${protonMailDarkmodeCss}" "$proton_dir/darkmode.css"
          cp -f "${protonMailDarkmodeCss}" "$proton_dir/service.css"
          pin_recipe "$proton_dir/package.json"
        fi

        # 5. Setup Instagram Direct Messages recipe with Catppuccin theme & version pinning
        instagram_dir="$recipes_dir/instagram-direct-messages"
        if [ -f "$instagram_dir/package.json" ]; then
          cp -f "${instagramDarkmodeCss}" "$instagram_dir/darkmode.css"
          cp -f "${instagramDarkmodeCss}" "$instagram_dir/service.css"
          pin_recipe "$instagram_dir/package.json"
        fi

        # 6. Pin Facebook & Messenger recipe versions to prevent upstream theme wipe
        for fb_svc in facebook messenger; do
          fb_dir="$recipes_dir/$fb_svc"
          if [ -f "$fb_dir/package.json" ]; then
            pin_recipe "$fb_dir/package.json"
          fi
        done

        # user.css loads independently of each service's dark-mode toggle.
        for aero_service in whatsapp messenger; do
          aero_dir="$recipes_dir/$aero_service"
          if [ -f "$aero_dir/package.json" ]; then
            case "$aero_service" in
              whatsapp) aero_css=${whatsappCss} ;;
              messenger) aero_css=${messengerCss} ;;
            esac
            install_css "$aero_css" "$aero_dir/user.css"
            install_css "$aero_css" "$aero_dir/service.css"
            install_css "$aero_css" "$aero_dir/darkmode.css"
          fi
        done
        messenger_dir="$recipes_dir/messenger"
        if [ -f "$messenger_dir/package.json" ]; then
          if [ -f "$messenger_dir/user.js" ] && ! grep -q 'amethyst-messenger-hook' "$messenger_dir/user.js"; then
            cp "$messenger_dir/user.js" "$messenger_dir/user.pre-aero.js"
          fi
          cp -f ${./messenger-aero.js} "$messenger_dir/amethyst-messenger.js"
          cat > "$messenger_dir/user.js" <<'EOF'
    // amethyst-messenger-hook: preserve an existing user script, then style bubbles.
    module.exports = (...args) => {
      const fs = require('fs');
      const path = require('path');
      const previous = path.join(__dirname, 'user.pre-aero.js');
      try {
        if (fs.existsSync(previous)) {
          const run = require(previous);
          if (typeof run === 'function') run(...args);
        }
      } catch (error) { console.warn('Previous Messenger user script:', error); }
      require('./amethyst-messenger.js')();
    };
    EOF
        fi

        # 7. Pin the theme settings Ferdium keeps in its own JSON, which nothing
        # else in this config touches. A fresh profile (the dell) comes up with
        # universalDarkMode on, adaptableDarkMode on, no grayscale and the stock
        # purple accent, so the Catppuccin CSS lands on a UI that is still asking
        # for light mode and tinting the ribbon #7367F0. Merged key by key rather
        # than written wholesale: Ferdium owns this file and rewrites it whenever
        # a setting is toggled in the UI, so replacing it would drop every other
        # preference it has accumulated.
        settings="$ferdium_dir/config/settings.json"
        lock_pid=$(readlink "$ferdium_dir/SingletonLock" 2>/dev/null || true)
        lock_pid="''${lock_pid##*-}"
        case "$lock_pid" in
          ""|*[!0-9]*) running=false ;;
          *) if kill -0 "$lock_pid" 2>/dev/null; then running=true; else running=false; fi ;;
        esac
        # Ferdium owns settings.json while running; apply defaults when closed.
        if "$running"; then exit 0; fi
        if [ ! -e "$settings" ]; then printf '{}\n' > "$settings"; fi
        if [ -s "$settings" ]; then
          tmp_settings=$(mktemp)
          if ${jq} '
            .darkMode = true
            | .universalDarkMode = false
            | .adaptableDarkMode = false
            | .accentColor = "${palette.accent}"
            | .progressbarAccentColor = "${palette.accent}"
            | .useGrayscaleServices = false
            | .grayscaleServicesDim = 50
          ' "$settings" > "$tmp_settings" && [ -s "$tmp_settings" ]; then
            cp -f "$settings" "$settings.bak"
            mv -f "$tmp_settings" "$settings"
          else
            rm -f "$tmp_settings"
          fi
        elif [ ! -s "$settings" ] && [ -s "$settings.pre-catppuccin.bak" ]; then
          cp -f "$settings.pre-catppuccin.bak" "$settings"
        fi
  '';
in
{
  setup = ferdiumCatppuccinScript;
  inherit
    appCss
    messengerCss
    whatsappCss
    discordDarkmodeCss
    ;
}
