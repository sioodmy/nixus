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

## Blokada Quickshell, 25 października 2026

- Hyprlock zastąpiony osobnym procesem Quickshella, protokołem
  `ext-session-lock-v1` i profilem PAM `aero-lock`. Restart panelu nie zatrzymuje
  procesu blokady. Hypridle nadal korzysta z `aero-lock`.
- Pakiet `aeroshell` zbudowany dla aarch64-linux; profil PAM wyewaluowany dla
  Pandory i Calypso. Sprawdzona ścieżka narzędzi usługi hypridle.
- Wygląd oraz prawdziwa powierzchnia blokady uruchomione w izolowanym Sway
  1440 × 900, bez błędów QML. Aktualny `previews/lockscreen.png` przedstawia
  ten sam komponent w trybie podglądu.
- `tests/lock.sh` sprawdza prawdziwą konwersację PAM z testowym hasłem przez
  `pam_exec`: po odrzuceniu sesja pozostaje zabezpieczona, a po zaakceptowaniu
  blokada znika i proces kończy się poprawnie. Profil testowy jest tworzony
  wyłącznie w katalogu tymczasowym. Test nie zmienia LockedHint prawdziwej sesji.
- Nie testowano hasła użytkownika, klucza U2F, hotplugu monitorów ani cyklu
  uśpienia na działającym Hyprlandzie. Nowy profil PAM wymaga aktywacji NixOS;
  system nie został przełączony w ramach tej zmiany.

## Ikony i lista zadań, 25 października 2026

- Pakiety `aero-icons` i `aeroshell` zbudowane dla aarch64-linux. Listy pakietów
  obu konfiguracji, Pandory i Calypso, wyewaluowane z nowym motywem ikon.
- 56 autorskich ikon SVG, 209 aliasów. `icons/tests/coverage.py` parsuje pliki,
  sprawdza aliasy i potwierdza pokrycie wszystkich 58 lokalnych/systemowych
  wpisów `.desktop`. Grafika otwierana poprawnie przez Qt w działającym shellu.
- Usunięte tray, cztery przypięte aplikacje oraz osobna siatka sześciu pulpitów.
  Jedna przewijana lista pokazuje poszczególne okna w grupach według pulpitu
  i monitora. Pusty aktywny pulpit pozostaje dostępny.
- `tests/tasks.mjs`: prawdziwe komponenty QML i natywne modele Hyprlanda
  w izolowanym Sway, ze sterowanym serwerem IPC. Sprawdzone duplikaty app ID,
  filtrowanie monitora, komendy aktywacji Lua, przenoszenie/zamykanie okien,
  zmiana aktywnego pulpitu oraz puste grupy. Brak błędów QML i pętli powiązań.
- `previews/desktop.png` to zrzut launchera z nowymi ikonami. `tasks.png` i
  `taskbar.png` pokazują prawdziwy pasek z testowym modelem okien/pulpitów.
- Zagnieżdżony Hyprland nie wystartował z powodu niezgodności wersji
  `xdg_wm_base` w obecnym backendzie Aquamarine. Interakcje na rzeczywistym
  Hyprlandzie i mapowanie jego uchwytów Waylanda nie były testowane; test IPC
  obejmuje też aktywację okna po adresie przy braku takiego mapowania.
- Test wyszukiwania, formatowanie Nix i `git diff --check` przechodzą.
  Konfiguracja systemu nie była aktywowana.

## Logowanie Vista/Windows 7 i bateria

- Przebudowany wygląd blokady: duży obramowany kafel użytkownika, pole hasła
  z jasnym tłem, okrągła strzałka, mały zegar/data w rogu oraz stopka Aero.
  Renderowanie sprawdzone na osobnym Waylandzie 1440 × 900.
- Test PAM po zmianie interfejsu przechodzi: błędna odpowiedź nie odblokowuje
  sesji, poprawna testowa odpowiedź odblokowuje ją i kończy proces.
- Wspólny model UPower dla paska, panelu sesji i blokady; poprawne odróżnienie
  podłączenia zasilacza od aktywnego ładowania. Wypełnienie, procent, błyskawica,
  wtyczka, niski/krytyczny poziom oraz obsługa nieznanego stanu i braku baterii.
- `tests/battery.sh` sprawdza rozładowywanie, ładowanie, pełną baterię,
  wstrzymane ładowanie, progi 20/10%, brak estymaty, nieznany stan, nieprawidłowy
  odczyt i usunięcie baterii. Test nie zmienia stanu sprzętu.
- Zbudowany pakiet pokazuje rzeczywistą baterię i estymatę z UPower.
  `previews/battery-states.png` przedstawia natywny komponent z danymi testowymi.
  System nie został przełączony.
