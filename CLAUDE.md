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
adb install -r export/rpg007.apk
```

Tester: lägg `tests/test_*.gd` som ärver `res://tests/test_case.gd`, metoder som börjar på `test_`.
