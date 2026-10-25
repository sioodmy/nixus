# Amethyst Aero Cursors

Jasny, perłowo-fioletowy kursor z ciemnym konturem, cienkim odblaskiem i szklanym
pierścieniem zajętości. Własna grafika SVG obejmuje strzałkę, dłoń, chwytanie,
tekst, celownik, przesuwanie, kierunki zmiany rozmiaru, zakaz, oczekiwanie
i strzałkę z animacją pracy. Pierścienie mają 12 klatek po 60 ms.

`build.py` renderuje SVG przez librsvg i kompiluje Xcursor przez xcursorgen.
Rozmiary: 16, 20, 24, 28, 32, 40, 48, 56, 64, 72 i 96 px. Hotspoty skalują się
razem z grafiką. Standardowe nazwy i aliasy X11/CSS prowadzą do tych samych
kształtów. Rzadkie, dodatkowe kursory pochodzą z Bibata Modern Ice.

```sh
nix build path:.#aero-cursors
```

Gotowy motyw: `result/share/icons/Amethyst-Aero-Cursors`. Moduł GTK instaluje go,
ustawia nazwę w GTK 2/3/4, dconf i XCURSOR_THEME oraz tworzy zarządzany symlink
w `~/.local/share/icons`. Hyprland wybiera go jawnie przy starcie sesji.
Domyślny rozmiar wynosi 24 px. Zmieniony kursor działa także w Qt i XWayland;
aplikacje zachowujące poprzednią konfigurację trzeba uruchomić ponownie.

Autorska grafika SVG: MIT, plik `LICENSE`. Dodatkowe kursory Bibata: GPL-3.0,
plik `Bibata-LICENSE`; źródła i autorstwo:
[ful1e5/Bibata_Cursor](https://github.com/ful1e5/Bibata_Cursor/tree/v2.0.7).

Sprawdzono budowę na aarch64-linux, nagłówki Xcursor, rozmiary i hotspoty,
132 klatki każdego kursora animowanego oraz poprawność wszystkich aliasów.
Motyw został również wybrany przez IPC działającego Hyprlanda.
