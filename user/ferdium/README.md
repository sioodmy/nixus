# Ferdium · Amethyst Aero

Całe okno Ferdium oraz Discord, Messenger i WhatsApp korzystają z palety
`../quickshell/ui/palette.json`: ciemny fiolet, jasny tekst, szkliste paski,
wybrane karty i pola z delikatnym obramowaniem. Zdjęcia, awatary, emoji i kody QR
zachowują oryginalne kolory.

```sh
nix run path:.#ferdium
```

Najpierw zamknij działające Ferdium, aby nowe ustawienia i style zostały wczytane.
Pełna instalacja jest częścią zwykłego `nixos-rebuild switch --flake path:.#pandora`.
Nie trzeba włączać trybu ciemnego osobno w każdej usłudze.

`theme.nix` renderuje zwykły CSS bez pobierania zewnętrznych arkuszy:

- `aero-common.css`: paleta, font, obramowania i szkło;
- `aero-app.css`: pasek usług, ustawienia, zakładki, formularze i menu Ferdium;
- `aero-discord.css`: zmienne Discorda, kanały, edytor, nagłówek i menu;
- `aero-messenger.css`: zmienne Meta, panele, dymki, edytor i menu;
- `aero-whatsapp.css`: zmienne WhatsApp/WDS, panele, wiadomości i edytor.

`messenger-aero.js` oznacza malowane, zaokrąglone dymki tekstowe w tabeli
wiadomości. CSS nadaje odebranym ciemne szkło, a wysłanym jaśniejsze fioletowe
refleksy. Skrypt obsługuje nowe elementy Reacta i nie odczytuje treści wiadomości,
nie używa sieci ani pamięci konta. Pomija edytor, reakcje i załączniki graficzne.
Dotychczasowy `messenger/user.js`, jeśli istnieje, trafia do `user.pre-aero.js`
i jest nadal wykonywany przed nowym skryptem. Zmiany DOM są łączone w jeden
przebieg, zamiast wykonywania pętli dla każdej pojedynczej mutacji.

Wrapper przed każdym uruchomieniem instaluje `config/custom.css` oraz `user.css`,
`service.css` i `darkmode.css` w katalogach odpowiednich recipes. Pierwsze
nadpisane pliki CSS mają kopię `*.pre-aero.bak`. Zachowane są dotychczasowe
poprawki Discorda oraz skrypty Messengera i WhatsAppa odpowiedzialne za integrację.
Starsze style pozostałych usług nadal otrzymują zamianę kolorów na wspólną paletę.

Plik `settings.json` jest scalany kluczami; nie zastępujemy konfiguracji kont
i usług. Gdy Ferdium działa, instalator pomija modyfikację ustawień, żeby uniknąć
konfliktu z zapisem aplikacji. Przepisy są przypięte lokalną wersją `999.999.999`,
tak jak w poprzedniej konfiguracji. Zapobiega to nadpisaniu CSS przez updater,
ale również zatrzymuje aktualizacje skryptów tych integracji. Świadoma aktualizacja
recipes wymaga zdjęcia tego przypięcia i ponownego nałożenia motywu.

Usługa użytkownika `ferdium-aero` nakłada style przy starcie sesji; jednostka
`ferdium-aero.path` reaguje na zmiany katalogu recipes. Jeśli świeżo pobrana usługa
nie otrzymała jeszcze stylu, ponowne uruchomienie Ferdium nakłada go przed startem.

Weryfikacja instalatora na tymczasowym profilu:

```sh
nix build path:.#ferdium
bash user/ferdium/tests/setup.sh ./result
```

Test sprawdza zachowanie ustawień i skryptów usług, kopie CSS, wielokrotne
uruchomienie oraz pomijanie ustawień działającego profilu. Pełne sprawdzenie
widoków zalogowanych kont wymaga otwarcia usług; serwisy mogą zmieniać selektory
lub nadpisywać własne motywy rozmów. Podstawą są ich zmienne semantyczne, a nie
konkretne losowe nazwy klas Meta.

Sprawdzone na Ferdium 7.2.3/aarch64: budowa wrappera, test instalatora,
ewaluacja jednostki systemd i uruchomienie aplikacji na osobnym Waylandzie.
Style zostały również zainstalowane w obecnym profilu Ferdium. Do załadowania
całości potrzebny jest restart aplikacji; działające okno i konta nie były
restartowane podczas pracy.

Mechanizmy upstream: [custom.css Ferdium](https://github.com/ferdium/ferdium-app#styling),
[user.css w recipes](https://github.com/ferdium/ferdium-app/blob/develop/src/webview/recipe.ts),
[API CSS recipes](https://github.com/ferdium/ferdium-recipes/blob/main/docs/frontend_api.md).
