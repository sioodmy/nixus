# Amethyst Aero

Ciemnofioletowy pulpit inspirowany Vistą i Frutiger Aero. Nowy shell jest częścią
dotfiles; nie wymaga starego repozytorium `~/.config/quickshell` ani `backendqs`.

## Uruchomienie

Z katalogu dotfiles:

```sh
sudo nixos-rebuild switch --flake path:.#pandora
```

`path:.` uwzględnia również nowe pliki przed dodaniem ich do Gita. Po zapisaniu
ich w repozytorium można używać zwykłego `.#pandora`. Dla drugiego komputera
wybierz `calypso`.

Wyloguj się i zaloguj ponownie, aby wszystkie aplikacje odziedziczyły nowe
zmienne GTK/Qt, kursor i usługi sesji. Sam shell można przebudować i uruchomić:

```sh
nix build path:.#aeroshell
./result/bin/aeroshell
```

W aktywnej konfiguracji restart panelu: `systemctl --user restart quickshell`.
Aplikacje są uruchamiane w osobnych scope'ach systemd. Hyprlock również ma
osobny scope, niezależny od panelu i demona bezczynności.

## Obsługa

| Skrót | Działanie |
| --- | --- |
| Super+P / Super+Space | Launcher |
| Super+W | Wi-Fi |
| Super+B | Bluetooth |
| Super+Shift+O | Powiadomienia |
| Super+Alt+L | Blokada ekranu |
| Super+Alt+K | KeePassXC |
| Super+Ctrl+Shift+R | Restart panelu |
| Print / Super+Shift+S | Zrzut zaznaczonego obszaru |
| Super+Shift+W / Super+Shift+A | Zrzut pulpitu / aktywnego okna |

W launcherze: strzałki wybierają wynik, Enter uruchamia, Esc zamyka. Komendy
`:wifi`, `:bt`, `:audio` i `:power` otwierają odpowiednie panele po Enterze.
Ikony na pasku przełączają istniejące okna aplikacji; ponowne kliknięcia
przechodzą między jej oknami. Dodatkowe aplikacje pojawiają się na pasku.
Launcher jest przy górnej krawędzi ekranu, obok pionowego panelu.

Klawisze głośności, wyciszenia, mikrofonu i jasności pokazują szkliste OSD
u góry aktywnego ekranu. OSD znika po 1,7 s od ostatniej zmiany. Dźwięk jest
również obserwowany bezpośrednio przez PipeWire, więc zmiana suwakiem lub inną
aplikacją wywołuje ten sam wskaźnik. Jasność przechodzi przez `aero-brightness`;
głośność przez `aero-volume up|down|mute|mic-mute`. Zwiększanie głośności
klawiszami jest ograniczone do 100%, a jasność nie schodzi poniżej wartości
sprzętowej 1. OSD nie przejmuje fokusu ani kliknięć.

Wi-Fi obsługuje zapisane sieci, sieci otwarte, WPA/WPA2-PSK i WPA3-SAE oraz
zapominanie profili. Hasło jest przekazywane przez natywne API NetworkManagera,
bez argumentów procesu. Ukryte sieci, eduroam i profile firmowe konfiguruje
graficzny edytor połączeń; zapisane profile można później łączyć z panelu.

Bluetooth obsługuje wyszukiwanie, parowanie, łączenie, rozłączanie, zaufanie
i usuwanie par. Blueman zapewnia dialogi PIN/potwierdzenia i dodatkowe opcje.
Wyszukiwanie kończy się po zamknięciu panelu lub po minucie.

Panel zawiera też tray z menu aplikacji, głośność, mikrofon, jasność, MPRIS,
historię powiadomień i tryb nie przeszkadzać. Historia powiadomień pozostaje
w pamięci do restartu shella. Zrzuty trafiają do katalogu obrazów XDG
(`Screenshots`) i do schowka. Blokada następuje po 5 minutach bezczynności
i przed uśpieniem; ekran wyłącza się po 10 minutach.

## Wygląd

Wspólna paleta: [`ui/palette.json`](ui/palette.json). Korzystają z niej Quickshell,
GTK 3/4, Qt 5/6/Kvantum, obramowania Hyprlanda, Kitty, foot, Alacritty, tmux,
Zathura, btop, fzf, pomocniczy tofi i istniejące style usług Ferdium.
Przeglądarka: [Zen z motywem Amethyst Aero](../zen-browser/README.md),
uruchamiana z przycisku Internet na panelu.

Segoe UI pochodzi z używanego już pakietu `vista-fonts`; terminale używają
JetBrains Mono. Motyw ikon dziedziczy Oxygen, a foldery korzystają z jego
oryginalnego fioletowego wariantu. Kursor: Bibata Modern Ice. Menedżer plików:
Nemo. Kvantum zachowuje oryginalne wypukłości i gradienty KvDark, zmieniając
kolory skryptem [`../gtk/kvantum.py`](../gtk/kvantum.py).

Tapeta: [`ui/assets/wallpaper.png`](ui/assets/wallpaper.png).
Prompt i informacje o wygenerowaniu przez `image_gen`: [`ASSETS.md`](ASSETS.md).

W module Nix można ustawić `quickshell.panelSide = "right"` oraz
`quickshell.reducedMotion = true`. Launcher otwiera się bez animacji; opcja
ruchu dotyczy reakcji przycisków. Indeks aplikacji jest utrzymywany przez C++
w Quickshellu, a wyszukiwanie pracuje na znormalizowanych wpisach w pamięci.
Nie uruchamia procesów ani nie czyta plików przy każdym naciśnięciu klawisza.
Ranking uwzględnia częstość uruchamiania, zapisywaną w
`$XDG_STATE_HOME/amethyst-aero/usage.json`.

Programy rysujące własny interfejs, szczególnie strony internetowe i część
aplikacji Electron, mogą wymagać własnego motywu. GTK4/libadwaita otrzymuje
wspólną paletę i style; układ i dekoracje nadal zależą od aplikacji.

## Sprawdzenie

```sh
node user/quickshell/tests/search.mjs
bash user/quickshell/tests/notifications.sh
nix build path:.#aeroshell
```

Test powiadomień wymaga dostępnego Waylanda, `qs`, `notify-send`, `timeout`
i `dbus-run-session`. Uruchamia własną magistralę sesji i nie przejmuje demona
powiadomień pulpitu. `AERO_PREVIEW=1` wyłącza automatyczną rejestrację agenta
polkit i serwera powiadomień oraz akcje blokowania/zasilania w podglądzie.
Sterowanie prawdziwą siecią i urządzeniami nadal działa.

Podglądy w [`previews/`](previews/) to zrzuty działającego interfejsu
w osobnej sesji Waylanda, nie makiety HTML.
