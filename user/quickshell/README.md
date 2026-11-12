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
Aplikacje są uruchamiane w osobnych scope'ach systemd. Blokada Quickshell (`aero-lock`) ma
osobny scope, niezależny od panelu i demona bezczynności. Używa protokołu
Wayland `ext-session-lock-v1` i profilu PAM `aero-lock`. Odblokowuje wyłącznie
po poprawnym uwierzytelnieniu, na wszystkich monitorach jednocześnie.

Podgląd wyglądu bez blokowania sesji:

```sh
qs -p user/quickshell/ui/lock-preview.qml
```

## Touch ID

Blokada sama startuje Touch ID po zamknięciu sesji; wystarczy przyłożyć palec
do przycisku zasilania (czujnika). Wpisanie hasła w trakcie oczekiwania na palec
przełącza PAM na profil hasła, a przycisk **Użyj Touch ID** ponawia próbę.
Pierwsze odblokowanie po restarcie może wymagać hasła — tak jak w macOS,
`aurora.sep.requirePasswordAfterBoot` domyślnie czeka na pierwsze hasło od
uruchomienia, a potem Touch ID działa normalnie.

Rejestracja palca (jako zwykły użytkownik, bez sudo):

```sh
fprintd-enroll -f right-index-finger sioodmy
# przyciskaj przycisk zasilania / Touch ID, aż polecenie zakończy się sukcesem
fprintd-list sioodmy
fprintd-verify -f right-index-finger sioodmy
```

Gdy czujnik nie jest gotowy, sprawdź usługi i kalibrację:

```sh
systemctl status aurora-sep aurora-sep-ready fprintd
sudo aurora-touchid-setup --check
```

M1 nie przekazuje `/chosen/apfs-preboot-uuid`, więc host ma przypiętą osobną
tożsamość Linuksa w `/etc/modprobe.d` (`options apple_sep os_uuid_hi/lo`).
Nie wolno jej dublować w `boot.kernelParams`: parametry Rust są write-once
i drugi zapis kończy się błędem „invalid for parameter”. Po zmianie potrzebny
jest **pełny reboot**, nie sam `nixos-rebuild switch`:

```sh
sudo reboot
```

Po restarcie:

```sh
cat /sys/bus/platform/devices/*.sep/diag/os_identity   # -> explicit
```

Dopiero wtedy `fprintd-enroll` zacznie przyjmować palec.

`aurora.sep.requirePasswordAfterBoot = false;` w konfiguracji hosta pozwala
używać Touch ID już przy pierwszym odblokowaniu po starcie.

## Obsługa

| Skrót | Działanie |
| --- | --- |
| Super+P / Super+Space | Launcher |
| Super+W | Wi-Fi |
| Super+B | Bluetooth |
| Super+Shift+O | Powiadomienia |
| Super+Alt+L | Blokada ekranu |
| Super+Alt+K | KeePassXC |
| Super+Alt+H | Chomik i schowek plików |
| Super+Ctrl+Shift+R | Restart panelu |
| Print / Super+Shift+S | Zrzut obszaru lub okna (grimblast + slurp) |
| Super+Shift+W | Zrzut całego pulpitu (natychmiastowy) |
| Super+Shift+A | Zrzut aktywnego okna (grimblast) |

`aero-screenshot` korzysta z `grimblast` z hyprland-contrib: Print i
Super+Shift+S otwierają slurp do zaznaczenia obszaru lub okna (Esc anuluje),
Shift+A bierze aktywne okno, a Shift+W cały pulpit. Gotowy PNG trafia do
`~/Pictures/Screenshots`, do schowka i do chomika, który odtwarza animację
`AnimScreenShotFinish`.

W launcherze: strzałki wybierają wynik, Enter uruchamia, Esc zamyka. Komendy
`:wifi`, `:bt`, `:audio` i `:power` otwierają odpowiednie panele po Enterze.
Pasek pokazuje otwarte okna pogrupowane według pulpitu na danym monitorze.
Każde okno ma własną ikonę i podpowiedź z tytułem, również gdy należy do tej
samej aplikacji. Kliknięcie ikony aktywuje konkretne okno; mały nagłówek grupy
przełącza pulpit. Pusta bieżąca grupa pozostaje widoczna, a puste nieaktywne
pulpity znikają. Długa lista przewija się w dostępnym miejscu. Pasek nie ma
przypiętych aplikacji ani traya.
Launcher jest przy górnej krawędzi ekranu, obok pionowego panelu.

## Chomik i schowek plików

Mały chomik (84 × 88 px) mieszka nad oknami i nie rezerwuje miejsca na pulpicie.
Korzysta z oryginalnej grafiki i animacji ChomikBoxa od Chomikuj.pl: mruga,
rozgląda się i reaguje na przesuwanie oraz przeciąganie/upuszczenie pliku.
Podczas bezczynności losuje drobne ruchy — mrugnięcie, rozglądanie, drapanie
noska, bujanie, prychanie do góry, ziewanie, zezowanie — a rzadziej większe
czynności: kopanie norki, puszczanie samolotu, czytanie gazety, czytanie
książki i drzemka na poduszce (każda z oryginalnych sekwencji
start → pętla → zakończenie). Zabawę przerywa chwycenie chomika, upuszczenie
na niego plików albo włączenie muzyki.
Gdy MPRIS zgłosi rozpoczęcie odtwarzania, odtwarza `AnimMusicStart`.
Po zapisaniu zrzutu przez `aero-screenshot` dodaje PNG do schowka i odtwarza
`AnimScreenShotFinish`.
`quickshell.reducedMotion = true` pozostawia nieruchomą oryginalną klatkę.
Pochodzenie plików opisano w [`ASSETS.md`](ASSETS.md).
Przytrzymaj go lewym przyciskiem i przeciągnij, żeby zmienić położenie. Zapamiętuje
pozycję i monitor po restarcie. Kliknięcie otwiera **Chomicze policzki**;
kliknięcie poza panelem lub Escape zamyka panel. Na kilku monitorach przycisk
**Inny ekran** przenosi chomika na kolejny ekran.

Przeciągnij lokalne pliki z menedżera plików na chomika lub pole w jego panelu.
Schowek przechowuje do 100 odnośników do oryginałów, bez kopiowania i przenoszenia
plików. Można przeciągać je z listy dalej do innych aplikacji, otwierać i usuwać
ze schowka. Przeniesione/usunięte oryginały są oznaczane jako niedostępne;
foldery trzeba wcześniej spakować. **Opróżnij** zachowuje oryginalne pliki.

**Udostępnij wszystkie** lub **Udostępnij wybrane** uruchamia Cloudflare Quick
Tunnel, bez konta i domeny. Jeden plik jest pobierany bezpośrednio, kilka jako ZIP.
Udostępniana jest osobna kopia wybranych plików z chwili kliknięcia; późniejsze
dodawanie plików do schowka nie zmienia zawartości linku. Kopię i lokalny serwer
pobierania usuwa **Wyłącz link**, wygaśnięcie po 15 minutach, usunięcie pozycji,
opróżnienie schowka albo zamknięcie/restart shella. Zastąpienie linku unieważnia
poprzedni. Każdy, kto otrzyma pełny link z losowym kluczem, może pobrać pliki.
Komputer musi być włączony i mieć połączenie z Internetem. Serwer słucha tylko
na `127.0.0.1`, udostępnia jeden adres pobrania i nie wystawia katalogów.
Quick Tunnel ma zmienny adres i nie gwarantuje dostępności
([dokumentacja Cloudflare](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-tunnel/do-more-with-tunnels/trycloudflare/)).

**Schowaj** ukrywa chomika do restartu. Skrót Super+Alt+H lub `aero-hamster` przywołuje go
i otwiera/zamyka panel. Wyłączenie na stałe: `quickshell.hamster.enable = false;`.
Stan schowka i pozycja są w `$XDG_STATE_HOME/amethyst-aero/hamster.json`.
Podgląd uruchamiany bez pakietu wymaga `python3`, `cloudflared` oraz `wl-copy`
w `PATH` i wtyczki WebP z Qt Image Formats w `QT_PLUGIN_PATH`;
pakiet `aeroshell` zapewnia te zależności.

Sprawdzenie backendu (bez publikowania plików; lokalny tunel testowy):

```sh
python3 -B user/quickshell/tests/hamster.py
```

Test QML w izolowanym Sway opisany jest w [`VALIDATION.md`](VALIDATION.md).

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

Panele systemowe zawierają głośność, mikrofon, jasność, MPRIS,
historię powiadomień i tryb nie przeszkadzać. Historia powiadomień pozostaje
w pamięci do restartu shella. Zrzuty trafiają do katalogu obrazów XDG
(`Screenshots`) i do schowka. Blokada następuje po 5 minutach bezczynności
i przed uśpieniem; ekran wyłącza się po 10 minutach.

## Wygląd

Wspólna paleta: [`ui/palette.json`](ui/palette.json). Korzystają z niej Quickshell,
GTK 3/4, Qt 5/6/Kvantum, obramowania Hyprlanda, Kitty, foot, Alacritty, tmux,
Zathura, btop, fzf, pomocniczy tofi i istniejące style usług Ferdium.
Przeglądarka: Helium.

Segoe UI pochodzi z używanego już pakietu `vista-fonts`; terminale używają
JetBrains Mono. [Pakiet ikon Amethyst Aero](../icons/README.md) ma 56 własnych
projektów SVG i 209 aliasów: fioletowe szkło, jasne krawędzie oraz indywidualne
symbole aplikacji. Obejmuje wszystkie 58 obecnych wpisów `.desktop`; pozostałe
ikony systemowe dziedziczy z Oxygen i Adwaity. Kursor: [Amethyst Aero](../cursor/README.md). Menedżer plików:
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
oraz nagranie wideo interakcji z oknami w Sway.
