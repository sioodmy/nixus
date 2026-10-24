# Sprawdzenie, 24 października 2026

- Pakiet `aeroshell` i pakiet motywów GTK/Kvantum zbudowane dla aarch64-linux.
- Moduły Nix dla `pandora` i `calypso` wyewaluowane, włącznie z usługą shella,
  konfiguracją Hyprlanda i deklaracją PAM dla Hyprlocka. Pakiet x86_64 nie był
  budowany na maszynie ARM.
- Zbudowany shell, Quickshell 0.3.2 / `9b0f339b19057f4731bf3b48293307d7ef241671`,
  uruchomiony w osobnej sesji Waylanda 1440 × 900. Sprawdzone: wszystkie sześć
  paneli przez IPC, wpisywanie do launchera, wyszukiwanie i zamknięcie przez Esc.
  Brak błędów QML i pętli powiązań w tym teście.
- Test rankingu wyszukiwania przechodzi; 2000 sztucznych wpisów zajmuje około
  2 ms/zapytanie w Node 22.21.1. Jest to pomiar algorytmu, nie obietnica czasu
  całego launchera w QML.
- Serwer powiadomień przetestowany na osobnej magistrali D-Bus: odbiór, śledzenie,
  zachowanie treści jako tekstu i wyczyszczenie historii.
- `Hyprland --verify-config` przyjmuje wyrenderowaną konfigurację Lua.
- Hyprlock 0.9.6 renderuje konfigurację bez błędów parsera. Hypridle 0.1.8
  przyjmuje konfigurację i oba progi bezczynności. Odblokowania hasłem nie
  testowano; właściwy profil PAM zostanie zainstalowany przez moduł NixOS.
- Wygląd GTK 3, GTK 4/libadwaita i Kvantum sprawdzony na działających aplikacjach.
- Wi-Fi i Bluetooth pokazują prawdziwe dane urządzeń. Nie przełączano sieci,
  nie parowano nowych urządzeń i nie testowano haseł użytkownika.
- Formatowanie Nix i `git diff --check` przechodzą.

Pełny build systemu Pandory został zatrzymany, gdy rozpoczął budowę kernela
Asahi 7.2.12. Wcześniejsza, zastana w `flake.lock` aktualizacja
`nixos-apple-silicon` z `12cd234…` do `46e80bc…` wymaga tej kompilacji;
działająca sesja używa kernela 7.1.13. Te zmiany wejść pozostały zachowane.
System nie został przełączony.

Zrzuty w `previews/` pochodzą z działającego pakietu i Hyprlocka w izolowanej
sesji. Nie przedstawiają testu rzeczywistego uwierzytelniania. Do testów warstw
użyto Sway, więc rozmycie Hyprlanda i jego mechanizm przejmowania fokusu nie
były częścią tej sesji testowej.

## Dopracowanie Ferdium, Zen i OSD

- Nowe pakiety shella, Zen i Ferdium zostały zbudowane dla aarch64-linux.
- W osobnej sesji Waylanda potwierdzono pozycję launchera przy górnej krawędzi,
  renderowanie OSD głośności, jasności i mikrofonu oraz wygaszenie po 1,7 s.
  Wywołania testowe IPC nie zmieniały rzeczywistych poziomów sprzętu.
- OSD dźwięku korzysta z sygnałów PipeWire; klawisze sprzętowe mają również
  jawną informację zwrotną przez IPC. Jasność przechodzi przez nowy wrapper.
- Popup Zen został otwarty w działającej przeglądarce i sprawdzono obliczone
  gradienty, obramowanie 1 px oraz cienie aktualnego `.urlbar-background`.
- Instalator Ferdium przeszedł test zachowania ustawień, kopii plików,
  wielokrotnego uruchomienia, aktywnego profilu i istniejącego user.js Messengera.
- Klasyfikator dymków sprawdzono w przeglądarce na przykładowym DOM rozmowy:
  odebrane, wysłane, nowe elementy, pomijanie załączników i edytora. Nie jest
  to test zalogowanego konta Meta ani zrzut prawdziwej rozmowy.
- Aktualne Ferdium 7.2.3 sprawdzono pod kątem ładowania user.css przez
  `textContent` i uruchamiania user.js po gotowości DOM; obsługuje nowy hook.
- Style i hook Messengera zainstalowano w obecnym profilu. Aplikacje użytkownika
  i system nie były restartowane; nowe mapowanie klawiszy i shell wymagają
  aktywacji konfiguracji.
