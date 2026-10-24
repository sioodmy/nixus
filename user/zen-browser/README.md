# Zen · Amethyst Aero

Zen Beta z własnym motywem ciemnofioletowego szkła, kartami po lewej,
Segoe UI i stroną nowej karty z tapetą pulpitu. Kolory pochodzą ze wspólnego
`../quickshell/ui/palette.json`. Motyw obejmuje karty, pasek adresu, menu,
nową kartę oraz ustawienia i dodatki. Strony internetowe zachowują swoje style.
Sidebar i pasek narzędzi korzystają ze wspólnej powierzchni okna, bez osobnego
jasnego panelu. Wyszukiwanie ma szkliste tło, obramowanie, cień i wypukłe wyniki;
styl obejmuje aktualny selektor `.urlbar-background` Zen 1.23.4b.
uBlock Origin jest dostarczany jako podpisany XPI z Mozilla Add-ons, przypięty
sumą SHA-256 w pakiecie. Instaluje się automatycznie i jest włączony przy
pierwszym starcie, również bez pobierania rozszerzenia z sieci. Można go
wyłączyć w dodatkach; polityka nie wymusza blokady odinstalowania.

Uruchomienie bez przebudowy całego systemu:

```sh
nix run path:.#zen-aero
```

Instalacja w konfiguracji NixOS (z katalogu repozytorium):

```sh
sudo nixos-rebuild switch --flake path:.#pandora
```

Po ponownym zalogowaniu przycisk Internet otwiera Zen, a usługa
`zen-browser-default` ustawia skojarzenia HTTP/HTTPS i HTML. Inne skojarzenia
plików zostają zachowane. Polecenia: `zen`, `zen-browser`, `zen --private-window`.
Helium pozostaje dostępny jako dodatkowa przeglądarka.

Wrapper przygotowuje profil `$XDG_CONFIG_HOME/zen/amethyst-aero`
(domyślnie `~/.config/zen/amethyst-aero`) i przy każdym uruchomieniu odświeża
symlinki do `user.js`, `chrome/userChrome.css` i `chrome/userContent.css`.
Nie wymaga importowania motywu ani przechodzenia kreatora. Historia, hasła,
rozszerzenia i sesja są zwykłymi zapisywalnymi danymi profilu. Wrapper zawsze
wybiera ten profil; istniejące profile Zen nie są modyfikowane.

Plik `settings.nix` zawiera ustawienia nakładane przy starcie, a oba pliki CSS
można edytować w tym katalogu. Po przebudowie zamknij wszystkie okna Zen
i uruchom przeglądarkę ponownie, aby załadować nowy CSS. Aktualizacje interfejsu
Zen mogą wymagać dostosowania selektorów; wersja przeglądarki jest przypięta
w `flake.lock`.

Źródła: [pakiet Nix](https://github.com/0xc000022070/zen-browser-flake),
[dokumentacja CSS Zen](https://docs.zen-browser.app/guides/live-editing).

Sprawdzone: budowa Zen Beta 1.23.4b i shella na aarch64-linux, ewaluacja pakietu
na x86_64-linux oraz modułu na obu hostach, formatowanie Nix i `git diff --check`.
Pierwszy start z pustym profilem sprawdzono w osobnym kompozytorze Waylanda;
[`preview.png`](preview.png) jest zrzutem działającej przeglądarki. Zastosowano
też regułę workspace 2 dla rzeczywistego `app_id=zen-aero`. Konfiguracja została
przygotowana w repozytorium; ta zmiana nie przełączała działającego systemu.
Na świeżym profilu potwierdzono również uBlock Origin 1.75.0: `active=true`,
`userDisabled=false`, `appDisabled=false` i instalację z lokalnego pliku XPI.
