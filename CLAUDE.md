# rpg007

Party-RPG för mobil (Android först, iPhone senare via moln-Mac). Spelaren är raidledaren för ett party.

## Ledstjärna

**En strid först, och ingenting annat förrän den känns skön.**
Inga talangträd, ingen loot, inga nya klasser förrän den första striden (4 hjältar, 1 boss, 5 knappar) känns bra.

## Pelare

- **WoW Vanilla–WotLK** – känslan: GCD-rytm, cast bars, spell queue, tunga träffar, tydliga ljud, läsbara bossmekaniker.
- **Path of Exile** – karaktärsbygget (senare).
- **Dragon Age: Origins** – taktiken: regler per hjälte, taktisk paus, kombinationer.

## Teknik

- Godot 4.7.2, GDScript, renderer GL Compatibility, 1280×720 liggande (`canvas_items`/`expand`).
- Stridslogiken i `src/combat/` ska vara ren logik utan noder, så den kan testas och simuleras headless.
- Data (klasser, förmågor, fiender) i `data/`.
- Allt UI ska fungera med touch; musklick emuleras som touch.

## Kommandon

```bash
# Kör tester
godot --headless --path . --script res://tests/run_tests.gd

# Starta spelet
godot --path .

# Skärmdump av spelet (sparas efter 30 bildrutor, sedan avslut)
godot --path . -- --screenshot=/tmp/shot.png --frames=30

# Bygg debug-APK och installera på ansluten Android-telefon
godot --headless --path . --export-debug Android export/rpg007.apk
~/Library/Android/sdk/platform-tools/adb install -r export/rpg007.apk
```

## Verktygskedja (iMac 2017, macOS 13)

Homebrew bygger inte längre färdiga paket för macOS 13 – installera inte Java/Android via brew (kompilerar i timmar).

- Godot 4.7.2: `/Applications/Godot.app`, `godot` i PATH. Exportmallar i `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`.
- JDK 17 (Temurin): `~/Library/Java/JavaVirtualMachines/jdk-17.0.20.1+1/Contents/Home`
- Android SDK: `~/Library/Android/sdk` (platform-tools, build-tools 36.1.0, platforms android-36)
- Debug-nyckel: `~/.android/debug.keystore` (standard: android/androiddebugkey)
- Exporten är utan Gradle (`gradle_build/use_gradle_build=false`), endast arm64-v8a.

Tester: lägg `tests/test_*.gd` som ärver `res://tests/test_case.gd`, metoder som börjar på `test_`.
