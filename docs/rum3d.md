# Rumsögonblick i 3D (underlag för 0.18)

Ett kort, överhoppbart 3D-ögonblick när sällskapet går in i ett rum på rumskartan: dörren öppnas,
sällskapet går in, kameran glider efter genom dörren och svänger upp mot rummets mittpunkt, och
rummets händelse spelas. Ca 4,8 s. Ett tryck hoppar över.

Inget är inkopplat i spelflödet ännu – allt ligger i `scripts/rooms/`.

## Filer

- `scripts/rooms/room_world.gd` – `RoomWorld` (Node3D): rummet byggt i kod som `CryptWorld`.
  Väggar, golv, korridor, dubbeldörr i främre väggen och mittpunkten. Ingen ny modellfil:
  statyn i helgedomen är `torvald.glb` i sten, fången i buren är `alva.glb` i grått (via `UnitModel`; `sigrun.glb` följer inte med i APK:n).
- `scripts/rooms/room_moment.gd` – `RoomMoment` (Control): ögonblicksspelaren. Lägger rummet i en
  egen `SubViewport` (egen 3D-värld) och täcker hela skärmen, så den kan läggas ovanpå vilken
  2D-skärm som helst, t.ex. rumskartan.
- `scripts/rooms/room_lab.tscn` + `room_lab.gd` – testscen.

## Rumstyper (`RoomWorld.KINDS`) och stilar (`RoomWorld.STYLES`)

| kind | Svenskt namn | Händelse |
|---|---|---|
| `treasure` | Skattkammare | Kistans lock fälls upp, guldet glöder, gnistor stiger och glimtar i mynthögarna |
| `shrine` | Helgedom | Ett ljusschakt faller över altaret, stenstatyn lyser upp, ljuspartiklar stiger |
| `prisoner` | Fånge | Hänglåset faller med gnistor, burdörren glider åt sidan, fången vänder sig mot sällskapet |
| `inscription` | Inskrift | Runorna på stentavlan tänds rad för rad, damm virvlar |
| `campfire` | Lägereld | Elden flammar upp och lugnar sig, glöd stiger, sovfällar runt elden |
| `portal` | Portal | Virveln till Nether öppnar sig i stenringen, partiklar sugs in |

Stilar: `crypt` (mörk sten, facklor, runband, ben på golvet) och `chapel` (ljus kalksten, glasfönster,
ljusstakar, röd matta). Namnen finns i `RoomWorld.NAMES`.

## Anrop

```gdscript
var moment := RoomMoment.create("treasure", "chapel", run.party)  # hjält-id:n, som i data/heroes.json
add_child(moment)
var skipped: bool = await moment.finished
# … visa rummets dialog/belöning ovanpå, eller direkt:
moment.queue_free()
UnitModel.free_shared()  # när inga fler UnitModel används (som när striden stängs)
```

- `create(kind, style, hero_ids, data = {})` – `data` är `GameData.load_all()`; skicka med den om den
  redan finns, annars laddas den.
- `finished(skipped)` skickas när händelsen spelats klart (efter `LENGTH` = 4,8 s) eller vid tryck.
  Ögonblicket ligger kvar på sista bilden (`hold_last_frame = true`, kameran andas långsamt) tills
  anroparen frigör det – lämpligt att lägga rummets val/dialog ovanpå. Det är anroparens sak att
  frigöra det; trycket efter `finished` fångas fortfarande av ögonblicket (mouse_filter STOP).
- `play_sound = false` före `add_child` stänger av ljuden (kryptstämning, fotsteg, händelseljud).
- `msaa` (standard `Viewport.MSAA_2X`) och `shadows` (standard `true`) sätts före `add_child` om
  telefonen behöver det. Skuggorna kommer bara från figurerna och mittpunkten.
- Upp till sex hjältar ställer sig i en båge framför mittpunkten (`RoomWorld.party_slots`).
- Tider (konstanter i `room_moment.gd`): tona in 0,35 s, dörren 0,3 s, sällskapet går 0,75 s,
  händelsen 2,7 s, slut 4,8 s. Kamerans bana är en kubisk kurva i `CAM_PATH`.

`RoomWorld` kan också användas för sig (`open_door()`, `reveal()`, `focus_point()`), t.ex. om rummet
ska ligga kvar som bakgrund medan spelaren väljer.

## Testscen

```bash
godot --path . res://scripts/rooms/room_lab.tscn -- --room=treasure --style=chapel
```

- `--room=all` visar alla rumstyper i båda stilarna i tur och ordning (tryck för nästa).
- `--party=paladin,brokk,alva` väljer sällskapet (standard: alla fem).
- `--shot=/tmp/rum.png --at=4.7` sparar en bild vid den tidpunkten och avslutar. Bilden av hela
  skärmen tas från rotfönstret, som inte får med SubViewporten vid den sortens skärmdump, så en
  andra bild `/tmp/rum_vp.png` sparas direkt ur 3D-vyn – granska den. (Med `--write-movie` syns allt.)

## Kvar att göra / idéer

- Koppla in i 0.18:s rumskarta (rummets stil från Realm: Kryptan → `crypt`, kapellet → `chapel`).
- Egna ljud för dörr, kista och lås (nu lånas `k_shield_wall`, `renew`, `k_shield_slam` …).
- Fler rumstyper (smedja, handlare, fälla) går att lägga till som en ny `_build_<kind>()` i `RoomWorld`.
- Prestanda på telefonen är inte uppmätt (se nedan).

## Prestanda (0.18)

GL Compatibility klarar bara ett fåtal ljus per objekt. Rummen har därför 4 OmniLight3D och månen
(DirectionalLight3D med skugga). Facklor, ljusstakar och glasfönster lyser med emission och delar på
ljus (ett per korridor, ett per sida i kryptan, ett i taket och ett vid bakväggen i kapellet). Det fjärde
ljuset är rummets händelse (i lägerelden är det elden). Figurernas egna ljus och träffblinkningen
(`material_overlay`) stängs av i ögonblicket. Väggar och utsmyckning kastar ingen skugga, och alla delar
som står still slås ihop till ett mesh per material (`RoomWorld._merge_static`).

| Mätt med `--bench` (händelsen, 2,7–4,8 s) | Ljus i scenen före → efter | Ritanrop före → efter |
|---|---|---|
| Kapellet, helgedom | 21 → 5 | 775 → 348 |
| Kryptan, helgedom | 16 → 5 | 710 → 422 |
| Kapellet, skattkammare | 21 → 5 | 848 → 370 |
| Kryptan, skattkammare | 16 → 5 | 829 → 424 |

Ljusen före räknar också figurernas ljus (släckta men aktiva). Bildtiden går inte att jämföra på iMacen:
GL-fönstret låses till skärmens 144 Hz, och med extra belastning (`--load`) spretar samma inställning med
flera millisekunder mellan körningar. Det som går att mäta (ljus per objekt och ritanrop) halverades.
Om 2× MSAA behövs går inte heller att avgöra här: mobila GPU:er med tile-rendering klarar ofta 2× MSAA
billigt, men det bör mätas på telefonen. Utan MSAA blir kanterna på golvfogarna och stängerna märkbart
taggiga. `RoomMoment.msaa` och `RoomMoment.shadows` finns för att kunna stänga av dem.

```bash
godot --path . res://scripts/rooms/room_lab.tscn -- --room=shrine --style=chapel --bench
```
