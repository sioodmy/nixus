{
  pkgs,
  ...
}:
let
  jq = "${pkgs.jq}/bin/jq";
  discordDarkmodeCss = ./ferdium-discord-darkmode.css;
  discordWebviewJs = ./ferdium-discord-webview.js;
  discordIndexJs = ./ferdium-discord-index.js;
  discordNotificationCompatJs = ./ferdium-discord-notification-compatibility.js;
  gmailDarkmodeCss = ./ferdium-gmail-darkmode.css;
  whatsappDarkmodeCss = ./ferdium-whatsapp-darkmode.css;
  protonMailDarkmodeCss = ./ferdium-proton-mail-darkmode.css;
  instagramDarkmodeCss = ./ferdium-instagram-darkmode.css;

  ferdiumCatppuccinScript = pkgs.writeShellScript "ferdium-catppuccin" ''
        recipes_dir="$HOME/.config/Ferdium/recipes"

        # 1. Setup Discord recipe with persistent theme & version pinning
        discord_dir="$recipes_dir/discord"
        mkdir -p "$discord_dir"

        # Copy Catppuccin stylesheet to service.css, darkmode.css, and user.css
        cp -f "${discordDarkmodeCss}" "$discord_dir/service.css"
        cp -f "${discordDarkmodeCss}" "$discord_dir/darkmode.css"
        cp -f "${discordDarkmodeCss}" "$discord_dir/user.css"

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
        if [ -d "$gmail_dir" ]; then
          cp -f "${gmailDarkmodeCss}" "$gmail_dir/darkmode.css"
          cp -f "${gmailDarkmodeCss}" "$gmail_dir/service.css"
          sed -i 's/"version": "[^"]*"/"version": "999.999.999"/' "$gmail_dir/package.json"
        fi

        # 3. Setup WhatsApp recipe with persistent Catppuccin theme & version pinning.
        # The stock darkmode.css is an outdated Franz-era stylesheet that no longer
        # matches web.whatsapp.com, and the recipe auto-updater wipes custom files.
        whatsapp_dir="$recipes_dir/whatsapp"
        if [ -d "$whatsapp_dir" ]; then
          cp -f "${whatsappDarkmodeCss}" "$whatsapp_dir/darkmode.css"
          cp -f "${whatsappDarkmodeCss}" "$whatsapp_dir/service.css"

          # Pin the version so the auto-updater stops overwriting the theme.
          # NOTE: this also freezes webview.js badge-selector updates; unpin
          # (delete the dir, restart Ferdium) if unread badges ever go stale.
          sed -i 's/"version": "[^"]*"/"version": "999.999.999"/' "$whatsapp_dir/package.json"
        fi

        # 4. Setup Proton Mail recipe with Catppuccin theme & version pinning
        proton_dir="$recipes_dir/proton-mail"
        if [ -d "$proton_dir" ]; then
          cp -f "${protonMailDarkmodeCss}" "$proton_dir/darkmode.css"
          cp -f "${protonMailDarkmodeCss}" "$proton_dir/service.css"
          sed -i 's/"version": "[^"]*"/"version": "999.999.999"/' "$proton_dir/package.json"
        fi

        # 5. Setup Instagram Direct Messages recipe with Catppuccin theme & version pinning
        instagram_dir="$recipes_dir/instagram-direct-messages"
        if [ -d "$instagram_dir" ]; then
          cp -f "${instagramDarkmodeCss}" "$instagram_dir/darkmode.css"
          cp -f "${instagramDarkmodeCss}" "$instagram_dir/service.css"
          sed -i 's/"version": "[^"]*"/"version": "999.999.999"/' "$instagram_dir/package.json"
        fi

        # 6. Pin Facebook & Messenger recipe versions to prevent upstream theme wipe
        for fb_svc in facebook messenger; do
          fb_dir="$recipes_dir/$fb_svc"
          if [ -d "$fb_dir" ]; then
            sed -i 's/"version": "[^"]*"/"version": "999.999.999"/' "$fb_dir/package.json"
          fi
        done

        # 7. Pin the theme settings Ferdium keeps in its own JSON, which nothing
        # else in this config touches. A fresh profile (the dell) comes up with
        # universalDarkMode on, adaptableDarkMode on, no grayscale and the stock
        # purple accent, so the Catppuccin CSS lands on a UI that is still asking
        # for light mode and tinting the ribbon #7367F0. Merged key by key rather
        # than written wholesale: Ferdium owns this file and rewrites it whenever
        # a setting is toggled in the UI, so replacing it would drop every other
        # preference it has accumulated.
        settings="$HOME/.config/Ferdium/config/settings.json"
        if [ -s "$settings" ]; then
          tmp_settings=$(mktemp)
          if ${jq} '
            .darkMode = true
            | .universalDarkMode = false
            | .adaptableDarkMode = false
            | .accentColor = "#89b4fa"
            | .progressbarAccentColor = "#89b4fa"
            | .useGrayscaleServices = true
            | .grayscaleServicesDim = 50
            | .useSelfSignedCertificates = true
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
  system.userActivationScripts.ferdiumCatppuccin = {
    text = "${ferdiumCatppuccinScript}";
  };

  systemd.user.services.ferdium-catppuccin = {
    description = "Setup Ferdium Catppuccin theme and recipes";
    wantedBy = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${ferdiumCatppuccinScript}";
      RemainAfterExit = true;
    };
  };
}
