# Zen · Amethyst Aero

Zen Beta z własnym motywem ciemnofioletowego szkła, kartami po lewej,
Segoe UI i stroną nowej karty z tapetą pulpitu. Kolory pochodzą ze wspólnego
`../quickshell/ui/palette.json`. Motyw obejmuje karty, pasek adresu, menu,
nową kartę, ustawienia i dodatki oraz YouTube, GitHuba i lokalny frontend T3 Code.
Pozostałe strony internetowe zachowują swoje style.
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

## Style stron

Pliki w `sites/` są automatycznie dopisywane do `userContent.css` przez
`package.nix`, z kolorami podstawionymi ze wspólnej palety pulpitu.
Nie trzeba instalować Stylusa ani importować stylów ręcznie.

- `common.css`: paleta, szkliste powierzchnie, wypukłe przyciski, zaznaczenie
  tekstu i widoczny fokus klawiatury.
- `youtube.css`: belka, nawigacja, wyszukiwarka, filtry, menu i opis filmu;
  obsługuje klasyczne komponenty Polymer oraz nowe komponenty `yt*`.
  Film i miniatury zachowują oryginalne kolory.
- `github.css`: zmienne Primer, belki, przyciski, pola i menu. Zieleń/czerwień
  statusów i diffów oraz rozróżnienie kolorów składni pozostają czytelne.
- `t3code.css`: sidebar, wiadomości, composer, menu, pola i bloki kodu przez
  zmienne motywu i selektory `data-slot` lokalnego T3.

Zakres to `youtube.com` (wraz z subdomenami), `github.com` (wraz z subdomenami)
oraz port **3773** na `localhost`, `127.0.0.1` i `[::1]`, po HTTP lub HTTPS.
Reguły dla T3 mają ukośnik po porcie, więc nie obejmują np. `:37730`.
Przy zmianie portu T3 zaktualizuj adresy w **obu** plikach `common.css`
i `t3code.css`. Inne lokalne projekty nie są stylowane.

W aplikacjach najlepiej pozostawić natywny ciemny motyw: CSS zmienia ich
powierzchnie również w jasnym trybie, ale wybór wariantu składni, terminala
rysowanego na canvasie czy obrazków README należy do aplikacji.
Style stron obowiązują tylko na ekranie, bez zmian wydruku. Szkliste powierzchnie
mają nieprzezroczyste tła; preferencja ograniczonej przezroczystości dodatkowo
wyłącza ich refleksy. Motyw nie dodaje animacji.

Po zmianach uruchom `nix run path:.#zen-aero` po zamknięciu wszystkich okien Zen.
Wrapper załaduje nowy CSS do dotychczasowego profilu. Uruchomienie z menu
systemowego używa wersji z ostatniej przebudowy NixOS.

Walidacja stylów stron: budowa `zen-aero` na aarch64-linux, `nixfmt --check`,
kontrola zakresu adresów i kontrastu palety oraz podgląd CSS na żywych stronach
YouTube (wyniki wyszukiwania), GitHub (repozytorium, także przy szerokości 390 px)
i T3 0.1.0 (ekran parowania). Podgląd używał wstrzykniętych reguł po podstawieniu
palety; zakres `@-moz-document` jest dostarczany przez Zen. Pełny czat T3 wymaga
zalogowanej sesji i nie był sprawdzany wizualnie.

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
