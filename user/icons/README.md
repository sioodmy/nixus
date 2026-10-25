# Amethyst Aero Icons

56 oryginalnych projektów SVG: aplikacje, fioletowe foldery, szklisty Start,
kontrolki sieci, dźwięku, multimediów i sesji. Wspólne materiały i oświetlenie,
indywidualne sylwetki zamiast jednakowych kafelków. Ikony skalują się od 16 do
512 px; nie wymagają fontów ani zewnętrznych obrazków.

`manifest.json` przypisuje 209 nazw ikon, identyfikatorów desktopowych i klas
okien do projektów z `build.py`. Pokrywa wszystkie 58 obecnie zainstalowanych
wpisów `.desktop`, w tym Kitty, Zen, Helium, Nemo, Signal, Ferdium, Thunderbird,
T3 Code, Neovim, KeePassXC, GIMP, Inkscape, Rnote, Prism, mpv, imv, Zathurę,
SMath, Tectonic, Yazi, btop, Deluge, Transmission, Nicotine+, Syncthing i narzędzia
systemowe. Programy terminalowe otrzymują ikonę wpisu uruchamiającego je w GUI.

Motyw jest instalowany przez moduł GTK oraz dostępny jako `aero-icons` we flake.
GTK 2/3/4, Qt 5/6 i Quickshell używają tej samej nazwy `Amethyst-Aero`.
Nieobsługiwane nazwy dziedziczą Oxygen, Adwaitę i hicolor. Quickshell rozwiązuje
też bazowe nazwy ikon z bezwzględnych ścieżek Nix oraz wpisy bez `Icon=` przez
identyfikator i nazwę aplikacji.

```sh
nix build path:.#aero-icons
python3 user/icons/tests/coverage.py result/share/icons/Amethyst-Aero
```

Test parsuje wygenerowane SVG, sprawdza wszystkie aliasy i porównuje motyw
z wpisami w `/run/current-system/sw/share/applications` oraz
`~/.local/share/applications`. Można podać dalsze katalogi jako argumenty.
Nowy program dodaje się przez alias istniejącej ikony albo nowy projekt
w `glyph()` i odpowiedni wpis manifestu.

Oryginalna grafika i generator są na licencji MIT. Dziedziczone motywy pozostają
osobnymi zależnościami i zachowują własne licencje; grafika Oxygen nie jest
kopiowana ani przepakowywana jako część autorskiego zestawu.
