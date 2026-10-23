# Prestanda, batteri, värme och robusthet på Android

Research för De edsvurna (rpg007), Godot 4.7.2, GL Compatibility, 1280×720 liggande, arm64. Skriven 2026-10-24 på
grenen `research-prestanda` (från `test-0.30`). Godot kördes **inte**: det här är webbresearch plus läsning av koden.
Siffror om vår kod är uppskattningar tills de är mätta på telefonen (mätplanen står i del 3).

**Kort sagt:** spelet ritar om hela skärmen i full takt överallt, också på stillastående menyer och kartor. Bakom
pergamentet ligger en brus-shader i helskärm, och i borgen ligger tre sådana lager ovanpå varandra. Det är troligen
den största källan till värme och batteriförbrukning, mer än 3D-striden. Den billigaste vinsten är en bildtaktsgräns
(30 på 2D-skärmarna, 60 i striden). Därefter bör pergamentet ritas en gång till en textur i stället för i varje bildruta.

---

## 1. Fynd ur källorna

### 1.1 Renderare: Compatibility eller Mobile

- Godots egen jämförelse: Compatibility har "Low base cost, but high scaling cost". Mobile har en medelhög baskostnad
  och skalar medelbra. Compatibility är alltså billigast för enkla scener och blir dyrare snabbare när scenen växer.
  OmniLight/SpotLight: 8 per mesh. Ljus med skuggor ritas i flera pass ("multi-pass approach") i Compatibility. MSAA
  fungerar för 3D men inte för 2D. Glow och dimma stöds i båda. Färgprecisionen i Compatibility är RGBA8.
  [Godot: Overview of renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- Mobile (Vulkan) på Android har haft många drivrutinskrascher. Godot 4.5.2 rekommenderade starkt en uppgradering för
  spel på Google Play som använder Vulkan Mobile, bland annat på grund av en drivrutinskrasch på Adreno 5xx.
  [Godot 4.5.2 RC 1](https://godotengine.org/article/release-candidate-godot-4-5-2-rc-1/). Enheter utan fungerande
  Vulkan faller ändå tillbaka till OpenGL ES.
- **Slutsats för oss:** stanna på Compatibility. Scenerna är små (ett rum, 4–8 figurer, några ljus), och just där är
  Compatibility billigast. Det fungerar också på fler telefoner. Byt bara om mätningar visar att 3D-striden är
  flaskhalsen, vilket den inte verkar vara.

### 1.2 Bildtakt, vsync och frame pacing

- Standardvärdena i `ProjectSettings` är `application/run/max_fps = 0` (ingen gräns), `vsync_mode = 1` (på) och
  `low_processor_mode = false`. Utan gräns ritar spelet alltså i skärmens takt, varje bildruta.
- Android 15 sätter spelens standardtakt till 60 Hz för att spara ström. Högre takt måste begäras via Frame Rate API
  eller Swappy, och systemet kan sänka takten vid lågt batteri eller värme.
  [Android: Optimize display refresh rate](https://developer.android.com/games/optimize/display-refresh-rate-change)
- Godot har fått Androids frame pacing-bibliotek Swappy. Commit-texten säger att det är på som standard och att
  målbildtakten styrs med `Engine.max_fps`
  ([commit](https://remotebranch.eu/Stowage/godot/commit/aaa0e2fddfead4a31afddc07a26cd6af0c19dacd)). Användare
  rapporterar att `max_fps = 60` ger cirka 60 fps men att skärmen ligger kvar på 120 Hz
  ([forum, 120 Hz](https://forum.godotengine.org/t/android-godot-why-fps-limit-display-refresh-rate-on-120-hz-devices-terraria-mobile-legends-example/132320)).
  Swappy byggdes för Vulkan-vägen, och det är **oklart** om det verkar i GL Compatibility. Det kontrolleras med mätplanen.
- En gräns som inte delar skärmens takt jämnt (60 fps på 90 Hz) kan ge ojämn pacing. 30 delar 60, 90 och 120 jämnt.
- `low_processor_mode` (`OS.low_processor_usage_mode`) ritar bara om när något har ändrats. Rapporter från Godot 3
  säger att det var avstängt eller flimrade på vissa Android-telefoner
  ([Godot Q&A](https://ask.godotengine.org/134721/how-to-use-low-processor-in-android)). Det fungerar dessutom inte
  med oss, eftersom våra skärmar begär omritning i varje bildruta (se 2.1). En bildtaktsgräns är säkrare.
- Communityråd (svagare källor): sänk `max_fps` på stillastående skärmar och höj den igen i spelet. Okapad takt på
  telefoner med hög uppdateringsfrekvens drar batteri och ger värme
  ([bugnet](https://bugnet.io/blog/how-to-fix-godot-mobile-game-draining-battery-while-idle),
  [forum](https://forum.godotengine.org/t/poor-performance-on-android/130697)).

### 1.3 GPU på mobil: fyllnadsgrad, shaders, skuggor, efterbehandling

Ur Godots [GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html):

- Mobil-GPU:er ritar i rutor (tile-based) och har en liten batteribudget. Det dyra är arbetet per pixel, inte antalet
  hörn: "consider using the simplest possible shaders you can reasonably afford".
- Efterbehandling och viewport-texturer, som behöver resultat från andra rutor, kan bli mycket långsamma på
  tile-GPU:er. Glow är en sådan efterbehandling.
- Skuggor kostar mycket per pixel. Gör skuggkartorna mindre och stäng av skuggor där det knappt syns.
- Genomskinlighet ger överritning. Håll genomskinliga ytor små. Det gäller också helskärmslager i 2D med alfa eller
  `blend_mul`.
- Testa om fyllnadsgraden är flaskhalsen genom att jämföra stort och litet fönster med vsync av.

**Konsekvens för oss:** en helskärms-shader på en telefon med 2400×1080 (2,6 miljoner pixlar) med 15 brusanrop per
pixel, varje anrop 4 `hash()` med `sin()`, ger ungefär 150 miljoner `sin` per bildruta och omkring 9 miljarder per
sekund i 60 fps. Det räcker för att värma en mellanklasstelefon av sig självt.

### 1.4 Texturer och minne

- 2D-bilder ska vara Lossless eller Lossy. VRAM-komprimering ger synliga artefakter i 2D. Lossy minskar bara filens
  storlek, **inte** videominnet. En RGBA8-bild på 1024×1024 med mipmaps tar ungefär 5,3 MiB okomprimerad mot 1,3 MiB med
  VRAM-komprimering. Mipmaps kostar cirka 33 % mer minne och behövs bara om de syns.
  ETC2 är standard på mobil; ASTC (High Quality) stöds bara i Forward+ och Mobile, **inte** i Compatibility.
  [Godot: Importing images](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html)
- Vi har `import_etc2_astc=true` (project.godot:36), vilket ger rätt format för 3D-texturer. 2D-illustrationerna är
  Lossless/Lossy (7 + 10 filer). Det stämmer med råden. Borgen och basen är 1536×1024, cirka 6 MiB var i VRAM. Det är
  inget problem i dag.

### 1.5 Värme (thermal throttling)

- Androids Thermal API (ADPF): `PowerManager.getThermalHeadroom(sekunder)` ger 0,0 (ingen strypning) till 1,0
  (kraftig strypning). `getCurrentThermalStatus()` har en lyssnare. Spel bör sänka bildtakt eller detaljnivå i tid.
  Finns från Android 11.
  [Android: Thermal API](https://developer.android.com/games/optimize/adpf/thermal)
- Godot exponerar inte detta i GDScript. Det kräver ett Android-plugin, och då Gradle-bygget, som vi har stängt av.
  **Inte värt det nu.** Med en bildtaktsgräns och billigare shaders kommer vi aldrig nära strypningen i ett turbaserat
  spel. Mät i stället med `dumpsys thermalservice` (del 3).

### 1.6 Livscykel: paus, återupptagning, bakåtknappen

- På Android skickar bakåtknappen eller bakåtsvepet `NOTIFICATION_WM_GO_BACK_REQUEST`. Med
  `application/config/quit_on_go_back = true`, som är standard, **avslutas appen**
  ([forum](https://forum.godotengine.org/t/how-to-handle-the-back-key-pressed-event-on-android-device/27557)).
  Vi har inte ändrat inställningen och lyssnar inte på notisen.
- Android 16 med target SDK 36: för appar som riktar sig mot API 36 anropas inte längre `onBackPressed()`/`KEYCODE_BACK`
  på det gamla sättet (prediktiv bakåtgest). React Native-appar började stängas av bakåtgesten
  ([itechguides](https://www.itechguides.com/fix-react-native-back-exits-on-android-16-after-target-sdk-36/)). Jag
  hittade inget motsvarande Godot-ärende. **Testa på en telefon med Android 16.**
- Android kan döda appen i bakgrunden utan förvarning. Spara därför vid `NOTIFICATION_APPLICATION_PAUSED`. Vi gör det
  för speltiden (run.gd:225–227), och körningen sparas efter varje rum. En pågående strid sparas inte. Det är
  acceptabelt eftersom Siralim fungerar likadant, men bör vara ett medvetet val.

### 1.7 Skärm: notch, säkert område, orientering

- Appar med target SDK 35 eller högre på Android 15+ ritar edge-to-edge och in i kamerahålet
  ([Android: display cutouts](https://developer.android.com/guide/topics/display-cutout)). Godot 4.5+ har
  exportvalet `screen/edge_to_edge`. Vi har `immersive_mode=true`, som döljer systemfälten. Kamerahålet ligger kvar och
  kan i liggande läge hamna över ‹ PROFILER uppe till vänster eller över tidslinjen.
  `DisplayServer.get_display_safe_area()` ger det säkra området. Vi läser det ingenstans.
- Android 16 (API 36) ignorerar orienterings- och storlekslås på stora skärmar (sw600dp: surfplattor, vikbara). **Spel**
  märkta med `android:appCategory="game"` är undantagna
  ([Android 16 behavior changes](https://developer.android.com/about/versions/16/behavior-changes-16),
  [orientation guide](https://developer.android.com/develop/adaptive-apps/guides/app-orientation-aspect-ratio-resizability)).
  Vårt exportval `package/app_category` står på standardvärdet, som i Godot bör vara Game. Kontrollera manifestet med
  `aapt dump badging` (del 3). `orientation=4` (sensor landscape) är rätt för oss.
- Godot 4.7 bör ha target SDK 36 och min SDK 24 som standard (forumuppgift, se
  [forum](https://forum.godotengine.org/t/how-to-target-latest-android-sdk/142631)). Google Play kräver nu API 36 för nya
  appar. Vår `export_presets.cfg` sätter inga SDK-värden, alltså gäller standardvärdena.

### 1.8 Ljud, start, APK

- `audio/driver/output_latency` är 15 ms som standard. För ett turbaserat spel räcker det. Korta ljudeffekter som WAV
  (29 st.) kostar ingen avkodning; musik och längre ljud som OGG (127 st.) är rätt.
- Scenbyten sker synkront (`change_scene_to_file`, run.gd:972). I Compatibility kompileras shaders första gången de
  används, så den första striden och det första rumsögonblicket hackar troligen. Ett stillastående laddningsögonblick
  (ResourceLoader i en tråd, eller en uppvärmning bakom svart) ger en jämnare upplevelse. Det är ingen batterifråga.
- APK-storleken styr inte spelet (CLAUDE.md). Modellerna (24 MiB) och illustrationerna (19 MiB) är de stora posterna.

---

## 2. Granskning av vår kod och våra inställningar

Rangordnat efter **effekt / insats**. "Effekt" är min uppskattning av batteri och värme, inte mätt.

| # | Vad | Var | Effekt | Insats |
|---|-----|-----|--------|--------|
| 1 | Ingen bildtaktsgräns: allt ritas i 60 (eller 90/120) fps | project.godot (saknar `application/run/max_fps`) | Hög | Mycket låg |
| 2 | Pergamentets brus-shader i helskärm, varje bildruta | parchment.gd:20–37; används i base_screen.gd:126, campaign_screen.gd:73, room_map_screen.gd:40 | Hög | Låg–medel |
| 3 | Borgen: tre helskärmslager med shader (pergament + bläck med TIME + ljus med blend_mul) | base_screen.gd:18–63, 126–131 | Hög | Medel |
| 4 | Alla 2D-skärmar ritar om i varje bildruta | tap_screen.gd:23–25, base_screen.gd:230–237, start_screen.gd:38–40, camp_screen.gd:31–33, find_reveal.gd:17–20 m.fl. | Medel (CPU) | Medel |
| 5 | Glow + filmisk tonemap + dimma i striden | crypt_world.gd:89–94, room_world.gd:165–168 | Medel | Mycket låg |
| 6 | Riktad skugga från månen i striden | crypt_world.gd:103, room_world.gd:178 | Medel | Mycket låg |
| 7 | Ett omniljus per figur som är släckt men finns kvar | unit_model.gd:112–116 (energi 0), 360 | Låg–medel | Mycket låg |
| 8 | Striden renderar 3D i full takt när den är pausad (makroredigeraren, skadeloggen, frågor) | battle.gd:330–336 (bara `time_scale = 0`) | Medel när det händer | Låg |
| 9 | Bakåtknappen avslutar appen | project.godot (`quit_on_go_back` standard true), inget `NOTIFICATION_WM_GO_BACK_REQUEST` | Robusthet | Låg |
| 10 | Kamerahålet tas inte med i layouten | `get_display_safe_area` används ingenstans | Robusthet | Medel |
| 11 | Rumsögonblick: egen SubViewport med MSAA 2× och CPU-partiklar | room_moment.gd:40, 79–81; room_world.gd:398–1000 | Låg (korta) | Låg |
| 12 | Synkrona scenbyten, shaderkompilering vid första användning | run.gd:970–972 | Hack, inte batteri | Medel |

### Detaljer och förslag

**1. Bildtaktsgräns (gör först).** Lägg till `application/run/max_fps=60` i project.godot som golv. Gör sedan en liten
hjälpfunktion i `Run` som sätter `Engine.max_fps = 30` när en 2D-skärm öppnas (borgen, kartorna, smedjan, biblioteket,
lägret, Förberedelser) och `60` i striden och under rumsögonblick och kartornas glid- och zoomanimationer.
Pjäsens gång i borgen och på rumskartan ser bra ut i 30. Halverad takt halverar ungefär GPU-arbetet på
2D-skärmarna. Dessutom delar 30 jämnt 60, 90 och 120 Hz.

**2. Pergamentet en gång, inte varje bildruta.** Shadern är statisk utom vid `set_view()` (zoomen). Förslag:
rendera den en gång till en `SubViewport` med `render_target_update_mode = UPDATE_ONCE` i halv eller full upplösning
och visa den som `TextureRect`. Under zoomen är `UPDATE_ALWAYS` billigt nog, eller så skalas den bakade texturen med
UV. Alternativt kan bruset beräknas med en tileable brustextur (en `texture()`-läsning i stället för 15 brusanrop).
Pergamentet syns överallt, så det här sänker kostnaden på alla 2D-skärmar.

**3. Borgens bläck och ljus.** `INK_SHADER` (2 fbm × 4 oktaver, med TIME) och `LIGHT_SHADER` (en loop över 10 ljus, med
`blend_mul`) täcker hela skärmen. Bläcket syns bara **utanför** murarna. Det kan beräknas en gång för `outside`-masken
(bakas) så att bara den långsamma rörelsen räknas. Eller rita lagret i halv upplösning (SubViewport 640×360, uppskalad;
bläck är mjukt och tål det). Ljusets fladder kan gå i 15–20 uppdateringar per sekund. Med punkt 1 och 2 blir borgen
ungefär en tredjedel så dyr.

**4. Omritning i varje bildruta.** `TapScreen._process` (tap_screen.gd:23–25) anropar `queue_redraw()` varje bildruta
för alla skärmar som ärver den, och borgen ritar planen och gränssnittet varje bildruta (base_screen.gd:236–237). I
Godot ritar viewporten om hela skärmen varje bildruta ändå, om inte `low_processor_mode` är på. Kostnaden här är CPU:
alla `draw_*`-anrop och all text byggs om. Rita bara om när `_t`-beroende saker syns (en pulserande ring, pjäsen som går,
en toast). Det är en förutsättning om vi någon gång vill prova `low_processor_mode` på menyerna. Punkt 1 ger det mesta
av vinsten ändå, så det här kan vänta.

**5–6. Glow, dimma och skugga i striden.** Glow i Compatibility är en efterbehandling med extra kopior och oskärpepass,
som är dyrt på tile-GPU:er (1.3). Månens skugga kostar ett extra pass. Gör ett **Android-läge**: stäng av glow och
skugga på `OS.has_feature("mobile")` och jämför skärmdumpar. Facklornas sken kan bära stämningen utan glow. Alternativt
behåll skuggan men sätt `directional_shadow_max_distance` kort och skuggkartan liten
(`rendering/lights_and_shadows/directional_shadow/size.mobile`). Mät före och efter med mätplanen.

**7. Släckta ljus.** `_cast_light` skapas med `light_energy = 0.0` för varje figur (unit_model.gd:115). Ett ljus med
energi 0 är troligen fortfarande synligt för renderaren och räknas mot gränsen på 8 ljus per mesh. Golvet nås av fler än
8 ljus: 3–4 facklor, nyckelljuset och 8 figurers ljus, plus glödljus. Då kan ljus poppa och shadern göra onödig loop.
Sätt `visible = false` när energin är 0 och slå på det i `_process` (rad 360) när ett kast börjar.

**8. Pausad strid.** När makroredigeraren eller skadeloggen är öppen står striden still (`Engine.time_scale = 0`,
battle.gd:331–336), men 3D-världen ritas fortfarande i full takt. Facklorna fladdrar också via `_t += delta` i
crypt_world.gd:39, som inte följer time_scale. Sänk `Engine.max_fps` till 30 medan en sådan ruta är öppen, eller dölj
3D-vyn bakom en ogenomskinlig panel.

**9. Bakåtknappen.** Sätt `application/config/quit_on_go_back=false`. Lyssna på `NOTIFICATION_WM_GO_BACK_REQUEST` i
`Run` och låt den betyda: stäng en öppen dialog eller hjälpruta → ‹ tillbaka på skärmen → i striden öppna pausen/GE UPP-
frågan → i borgen fråga "Avsluta?". Det är vad Android-spelare väntar sig, och ingen förlorar en strid på ett felsvep.
Testa på Android 16 med target SDK 36 (1.6).

**10. Säkert område.** Läs `DisplayServer.get_display_safe_area()` vid start och vid storleksändring. Lägg ett vänster-
eller högerindrag på knapparna i hörnen (‹ PROFILER, INSTÄLLNINGAR, LJUD, GE UPP, tidslinjen). Pergament och 3D-värld får
gå ända ut. Det räcker att `UiStyle` har en marginal som skärmarna använder.

**11. Rumsögonblick.** De är korta och kan hoppas över, och det finns en AV-knapp. Byt `MSAA_2X` mot
`MSAA_DISABLED` på mobil om mätningen visar att de är tunga (room_lab har redan `--no-msaa` för jämförelse).

**12. Hack vid första striden.** Ladda stridsscenen i en tråd (`ResourceLoader.load_threaded_request`) medan
Förberedelser eller grottan visas. Shaderhacket kan dämpas med en uppvärmningsruta: rita stridens material en gång
bakom en svart övertoning.

**Det som redan är bra:** Compatibility är rätt val. Exporten är bara arm64. ETC2/ASTC-import är på. 2D-bilderna är
Lossless/Lossy utan mipmaps. Korta ljud är WAV, musiken OGG. Speltiden sparas vid paus. CPU-partiklar (inte GPU) i
rumsögonblicken är rätt i Compatibility. Modellerna saknar LOD (`.glb.import`), vilket är rätt för 4–8 figurer på nära
håll.

---

## 3. Mätplan för telefonen

Mål: ett före- och ett efter-värde för punkterna 1–3 och 5–7, på en telefon i mellanklassen. Vardagstelefonen räcker,
men gärna också en äldre (Adreno 6xx/Mali-G7x).

### 3.1 Inbyggd mätare i spelet (liten insats)

Lägg till `--perf` (eller en dold knapp) som var femte sekund skriver till `print` (syns i `adb logcat`) och visar i
ett hörn:

```gdscript
var fps := Engine.get_frames_per_second()
var cpu_ms := Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
var draws := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
var objs := Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
var vram := Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / 1048576.0
var mem := Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0
print("PERF scen=%s fps=%d cpu=%.1fms draws=%d obj=%d vram=%.0fMiB mem=%.0fMiB" % [
		get_tree().current_scene.name, fps, cpu_ms, draws, objs, vram, mem])
```

GPU-tid per bildruta: `RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(), true)` och
sedan `RenderingServer.viewport_get_measured_render_time_gpu(rid)`. Det stöds inte på alla GL-drivrutiner; visa "–"
om värdet är 0.

### 3.2 adb-kommandon

```bash
ADB=~/Library/Android/sdk/platform-tools/adb
PKG=se.rpg007.prototype

# Spelets egna PERF-rader
$ADB logcat -s godot:V | grep PERF

# Bildtider (ritning och väntan) – nollställ, spela 60 s på en skärm, läs av
$ADB shell dumpsys gfxinfo $PKG reset
$ADB shell dumpsys gfxinfo $PKG          # "Janky frames", percentiler 50/90/95/99
$ADB shell dumpsys SurfaceFlinger --latency   # lista lager; följ med lagrets namn för exakta tider

# Skärmens faktiska uppdateringsfrekvens (60/90/120?) och appens begärda takt
$ADB shell dumpsys SurfaceFlinger | grep -iE "refresh|fps|frame rate"
$ADB shell dumpsys display | grep -iE "mActiveMode|refreshRate"

# Värme: status 0 = ingen, 1 = lätt, 2 = måttlig, 3 = svår …, och temperaturer
$ADB shell dumpsys thermalservice | head -40

# Batteri: nollställ, spela 15 min utan laddare, läs av
$ADB shell dumpsys batterystats --reset
$ADB shell dumpsys batterystats $PKG | grep -iE "Estimated power|cpu|screen" | head -30
$ADB shell dumpsys battery              # nivå och temperatur (temperature = tiondels °C)

# Minne
$ADB shell dumpsys meminfo $PKG | head -30

# CPU-last per tråd
$ADB shell top -H -n 1 -p $($ADB shell pidof $PKG) | head -20

# Manifestet: target SDK, appCategory (game?), orientering
~/Library/Android/sdk/build-tools/36.1.0/aapt dump badging export/rpg007.apk | grep -E "targetSdk|appCategory|orientation"
```

Skärmens uppdateringsfrekvens visas också med Utvecklaralternativ → "Visa uppdateringsfrekvens" på telefonen.

### 3.3 Protokoll

Kör varje fall i 5 minuter, med samma ljusstyrka (t.ex. 50 %), utan laddare och med flygplansläge:

1. **Borgen stillastående** (paladinen står still). Värstafall för 2D-shaders.
2. **Kampanjkartan** och **grottan** stillastående.
3. **Strid** med ALLA AUTO, 2×, kryptan (`--floor=2 --demo` går inte i en release-APK; spela in i normal ordning
   eller bygg en debug-APK).
4. **Striden pausad** med makroredigeraren öppen.

Anteckna per fall: fps, CPU-ms, GPU-ms (om tillgängligt), draw calls, `thermalservice`-status och batteritemperatur
efter 5 minuter, batteriprocent före och efter. Gör sedan om fallen med punkt 1 (bildtaktsgräns), punkt 2–3
(pergamentet bakat) och punkt 5–7 (Android-läge i striden), ett i taget.

**Tumregler:** batteritemperatur över 40 °C eller thermalstatus ≥ 2 efter 5 minuter i borgen är för mycket för en meny.
En timme spel ska inte ta mer än cirka 15–20 % batteri på en vanlig telefon. Om borgen kostar mer än striden är
2D-shaders flaskhalsen, vilket den här granskningen förutspår.

---

## Källor

- [Godot: Overview of renderers](https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html)
- [Godot: GPU optimization](https://docs.godotengine.org/en/stable/tutorials/performance/gpu_optimization.html)
- [Godot: Importing images](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_images.html)
- [Godot: ProjectSettings](https://docs.godotengine.org/en/stable/classes/class_projectsettings.html)
- [Godot: EditorExportPlatformAndroid](https://docs.godotengine.org/en/stable/classes/class_editorexportplatformandroid.html)
- [Godot 4.5.2 RC 1 (Vulkan Mobile på Android)](https://godotengine.org/article/release-candidate-godot-4-5-2-rc-1/)
- [Godot-commit: Swappy frame pacing](https://remotebranch.eu/Stowage/godot/commit/aaa0e2fddfead4a31afddc07a26cd6af0c19dacd)
- [Godot-forum: bildtaktsgräns och 120 Hz](https://forum.godotengine.org/t/android-godot-why-fps-limit-display-refresh-rate-on-120-hz-devices-terraria-mobile-legends-example/132320)
- [Godot-forum: target SDK i 4.7](https://forum.godotengine.org/t/how-to-target-latest-android-sdk/142631)
- [Godot-forum: bakåtknappen](https://forum.godotengine.org/t/how-to-handle-the-back-key-pressed-event-on-android-device/27557)
- [Godot Q&A: low processor mode på Android](https://ask.godotengine.org/134721/how-to-use-low-processor-in-android)
- [Godot-forum: dålig prestanda på Android](https://forum.godotengine.org/t/poor-performance-on-android/130697)
- [bugnet: batteri i viloläge (communityråd)](https://bugnet.io/blog/how-to-fix-godot-mobile-game-draining-battery-while-idle)
- [Android: Optimize display refresh rate](https://developer.android.com/games/optimize/display-refresh-rate-change)
- [Android: Thermal API (ADPF)](https://developer.android.com/games/optimize/adpf/thermal)
- [Android: Frame pacing (Swappy)](https://developer.android.com/games/sdk/frame-pacing)
- [Android 16: beteendeändringar](https://developer.android.com/about/versions/16/behavior-changes-16)
- [Android: orientering, bildförhållande och storlek](https://developer.android.com/develop/adaptive-apps/guides/app-orientation-aspect-ratio-resizability)
- [Android: display cutouts](https://developer.android.com/guide/topics/display-cutout)
- [Prediktiv bakåtgest med target SDK 36 (React Native-exempel)](https://www.itechguides.com/fix-react-native-back-exits-on-android-16-after-target-sdk-36/)
