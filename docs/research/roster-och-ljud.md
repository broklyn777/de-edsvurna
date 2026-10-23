# Röster och ljudkänsla – billigt (research, 2026-10-24)

Frågan: hur ger vi replikerna en röst och spelet bättre ljudkänsla utan att det kostar mycket tid, storlek eller
risk? Utgångsläge: svensk text i `data/dialog.json` (484 repliker, ca 36 000 tecken, i snitt 75 tecken; alla nya
repliker har fasta id:n, t.ex. `imma_elite_1`), porträtt, `DialogBox` som visar hela texten direkt (ingen skrivmaskin),
egna syntetiserade ljud (`tools/gen_sfx.py`, `tools/gen_audio.py`, numpy + Kenney CC0), 4 musikloopar i ogg och
`Sfx` (`scripts/battle/sfx.gd`) med kanalerna Music och Sfx. Hela `assets/audio/` är 5,1 MiB. Siralim har inga röster.

Påståenden med källa är märkta [n]; resten är våra slutsatser. Priser och villkor ändras – kontrollera innan köp.

---

## Rekommendation i korthet

| Rang | Alternativ | Kostnad (tid / pengar) | Storlek i APK | Risk |
|---|---|---|---|---|
| **1** | **Babbel per figur** (syntetiserade stavelser, tonhöjd per figur, rytm efter skiljetecken) + skrivmaskinstext | 1–2 sessioner, 0 kr | 0,1–0,4 MiB (eller 0 om allt syntetiseras i spelet) | Låg. Kan bli tjatigt – lös med volym, tak per replik och en inställning |
| 2 | **Musik som reagerar** (lager + stingers med `AudioStreamSynchronized`/`AudioStreamInteractive`) | 1–2 sessioner, 0 kr (gen_audio.py) | +1–2 MiB | Låg–medel: loopar måste vara taktexakta |
| 3 | **Delvis röst: bara hälsningsord** ("Mm?", "Edsvurne!", ett skratt) per figur, från en riktig skådespelare eller TTS, ovanpå babblet | Skådis: några tusen kr; TTS: < 300 kr | ca 1 MiB | Medel: kvaliteten på svensk TTS i korta utrop; röstrights |
| 4 | **Berättaren med röst** (Darkest Dungeon-vägen) – bara `narrator`-rutorna, ca 20–40 repliker | Skådis 1 dag, eller TTS | 1–3 MiB | Medel: en dålig berättare sänker hela spelet |
| 5 | **Full svensk röst** för ~1000 repliker (TTS) | 1–3 veckor arbete med regi och omtag, 500–2000 kr i TTS | 20–40 MiB | Hög: svensk TTS låter fortfarande platt i känslor, låser texten (varje ändring = ny inspelning), etik/licens |

**Mitt förslag:** gör 1 nu (det passar den mysiga tonen och Siralim-arvet), sedan 2 när striderna ska kännas
större. Spara 3–4 som en möjlig "putsning" före en release; de fasta id:na gör att vi kan lägga till dem utan att
röra datan. Avstå från 5 tills spelet är klart och texten frusen.

---

## 1. Babbel och nonsensröster – hur andra gör

**Animal Crossing (Animalese).** Varje bokstav i texten spelas som en inspelad bokstavs- eller stavelsesampel
(i japanska versionen kana-stavelser) i hög fart; därför låter engelska ord nästan begripliga. Figurerna har egna
tonhöjder, glada pratar högre och ledsna/arga lägre, och om man bläddrar fort snabbas talet upp [1]. Öppna
omimplementationer (npm `animalese-tts`, Rust-craten `animalese`) lägger till slumpad tonhöjd och intonationsglid vid
frågor och utrop [1]. En devlog visar hur man spelar in alfabetet i Audacity och exporterar en WAV per bokstav [2].

**Undertale/Deltarune.** Ett kort "blip" per synlig bokstav, olika ljud per figur (några figurer har helt andra
ljud) [3]. Den vanliga tekniken (t.ex. RPG Maker-plugin) är: för varje ny bokstav, om tillräckligt lång tid har gått,
spela en slumpad blip ur figurens lista [3]. Billigast av allt, men mer "dator" än röst.

**Celeste.** PowerUpAudio började med enkla synthljud per figur och modellerade **formanter** (vokalernas
spektraltoppar) med en parametrisk EQ som automatiserades över tiden, så att det låter som vokaler som glider. I
FMOD: ett ljudevent per figur som spelar så länge samtalet pågår; koden skickar porträttets känsla och FMOD hoppar
till den känslans del, där en slumpad följd av stavelser spelas. Ingen stavelse två gånger i rad, betonade stavelser
mer sällan. Känsla = tonhöjd: hög eller låg, stilla eller rörlig [4][5]. **Det här är närmast vad vi vill ha – och
vi kan göra formanttekniken i numpy i stället för i FL Studio.**

**Banjo-Kazooie.** Rare valde "mumble-speak" – korta grymtningar i olika tonhöjder – för att röstskådespel skulle
ta för mycket tid och för att riktigt tal kunde "förstöra spelarens bild av figurerna". Mumbo Jumbos röst är en
kör ur en låt i spelet, klippt i bitar som spelas slumpvis i slumpad tonhöjd [6].

**Hades (Supergiant).** Motsatsen: mer än 22 000 helt röstade repliker med färre än 20 anställda [7]. Det fungerar
för att röst är kärnan i deras spel och de har en fast skådespelargrupp (Logan Cunningham i alla deras spel) [8]. Inte
en modell för oss – men en påminnelse om att reaktiva repliker är det som gör det levande, och det har vi redan i text.

**Darkest Dungeon.** Bara berättaren (Wayne June som Förfadern) har röst; han reagerar på det som händer – kritiska
träffar, nära döden, en hjältes död [9]. Efter Junes död 2025 har Red Hook sagt att de inte kommer att återskapa
rösten med AI, trots att han hade samtyckt [9] – ett exempel på var branschens etik står.

**Godot.** Det finns inget färdigt Animalese-tillägg för Godot 4 som vi hittade; närmast är GDSAM (en GDExtension
kring den gamla talsyntesen SAM, med tonhöjd, mun och svalg) [10]. `AudioStreamGenerator` kan syntetisera ljud i
realtid från GDScript [11], men på Android är förrenderade sampel enklare och säkrare (GDScript-loopar som fyller
buffertar per bildruta kostar CPU och kan knastra). Slutsats: **bygg själva**, med förrenderade stavelser.

**Kostnad och storlek (vår uppskattning).** 12 figurer × 16 stavelser × 0,12 s, mono 22 kHz: PCM ca 1 MiB, med
Godots QOA-komprimering (WAV-standarden, ca 5:1 [12]) ca 0,2 MiB. CPU: ett `AudioStreamPlayer` per talare med
`pitch_scale`, högst 10–15 stavelser per sekund – försumbart.

---

## 2. Riktiga röster (TTS och skådespelare)

**Svensk TTS 2025–2026.**

- **Piper** (lokalt, gratis, MIT-motor). Den svenska rösten `sv_SE-nst` är tränad på NST-datan hos Språkbanken vid
  Nasjonalbiblioteket, **licens CC0** enligt modellkortet [13] – alltså fri även kommersiellt. Kvaliteten är
  begriplig men platt och "uppläsande"; duger för en robot eller ett test, inte för Imma.
- **Azure Neural TTS** (moln). Ungefär 15–16 USD per miljon tecken för standardröster, extra för HD-röster;
  gratisnivån anges olika (0,5–5 miljoner tecken/månad) [14]. Hela vår text × 3 omtag ≈ 250 000 tecken – ryms troligen
  i gratisnivån. Bra uttal, begränsad känsloregi på svenska. Kontrollera Microsofts villkor för att bädda in
  utdata i en produkt som säljs.
- **ElevenLabs** (moln). Betalplaner ger kommersiell rätt till ljud som genereras under planen; gratisplanen gör det
  inte, och källorna är oense om vad som gäller efter uppsägning [15]. Billigaste kommersiella plan ca 5–6 USD/mån
  [15]. Bäst känsloregi av de tre (v3, "70+ språk"), men vi hittade ingen oberoende granskning av svenskan – **testa tre
  Imma-repliker först**, som tidigare föreslaget. Leverantören får använda genererat innehåll för att träna [15].
- **Acapela** har svenska röster sedan länge; spel kräver en separat distributionslicens (pris på förfrågan). Inte
  billigt för vår skala.

**Etik och licens.** Google Play kräver ingen uttrycklig AI-märkning av spelinnehåll, men förbjuder AI-röster som
efterliknar verkliga personer på ett vilseledande sätt, och EU:s AI-förordning kräver märkning av viss AI-genererad
media [16]. Steam kräver redan att AI-genererat innehåll anges. Skådespelarförbund (SAG-AFTRA 2025) kräver samtycke
och redovisning för digitala kopior [16]. **Regel för oss:** klona aldrig en verklig persons röst; använd
leverantörens färdiga röster eller en skådespelare som skriftligt samtycker; skriv i krediterna vad som är syntetiskt.

**Storlek för ~1000 repliker.** 75 tecken ≈ 5 s tal. Ogg Vorbis mono 22 kHz kring 32–48 kbit/s ≈ 4–6 KiB/s →
20–30 KiB per replik → **20–30 MiB**. Med tanke på `apk-size`-regeln är det inget hinder (GitHub Release), men det
fyrdubblar APK:n för en sak spelet inte behöver.

**Delvis röst.** Bara hälsningar och utrop: 12 figurer × 8–10 korta ljud à 0,5–1,5 s ≈ 120 klipp ≈ **under 1 MiB**.
Det är det "Siralim-plus" som ger mest per krona: babblet bär texten, ett riktigt "Hm!" eller skratt i början ger
figuren en kropp. Skådespelare är bättre än TTS just för utrop (TTS är svagast i ljud som inte är ord).

---

## 3. Musik som följer spelet

Godot 4.3 införde `AudioStreamInteractive` (klipp + övergångstabell), `AudioStreamSynchronized` (lager som spelas
taktsynkront, med volym per lager) och `AudioStreamPlaylist` [17]. API:t [18][19]:

- `AudioStreamInteractive`: `set_clip_stream(i, s)`, `set_clip_name(i, n)`, `add_transition(from, to, from_time,
  to_time, fade_mode, fade_beats, use_filler_clip, filler_clip, hold_previous)`; `from_time` = IMMEDIATE / NEXT_BEAT /
  NEXT_BAR / END, `to_time` = SAME_POSITION / START / PREVIOUS_POSITION, `fade_mode` = DISABLED / IN / OUT / CROSS /
  AUTOMATIC; `CLIP_ANY = -1`. Byte i spelet: `player.get_stream_playback().switch_to_clip_by_name("boss")`.
  BPM, taktslag och takt sätts i importinställningarna för varje ogg [18].
- `AudioStreamSynchronized`: `stream_count`, `set_sync_stream(i, s)`, `set_sync_stream_volume(i, db)`; tona in ett lager
  med en Tween från −80 till 0 dB [18]. Man kan lägga en Interactive som ett av lagren i en Synchronized [20].

**Förslag för oss** (allt genereras av `gen_audio.py`, samma tempo och längd per Realm):

| Lager (Synchronized) | När det hörs |
|---|---|
| 0: bordun + harmonik (dagens loop, nedbantad) | alltid i grottan och striden |
| 1: rytm (puka, låg stråk-ostinato) | i striden |
| 2: spänning (mässing/kör) | elit, Nemesis, eller när någon i sällskapet har < 30 % liv |
| 3: lugn (harpa/flöjt) | på rumskartan/grottan utanför strid |

Stingers (korta ogg på Sfx-kanalen, gärna i loopens tonart): elit syns, trofé, sällsynt fynd, KOMBINATION!, nivå
upp, Paladinen ensam kvar. `AudioStreamInteractive` behövs bara för bossen (intro → loop → seger-svans, NEXT_BAR).
Storlek: 4 lager × 30 s × 4 KiB/s ≈ 0,5 MiB per Realm.

---

## 4. Ljud på mobilen: format

Enligt Godots dokumentation [12]: **WAV** är billigast att spela (hundratals samtidiga), med komprimeringen QOA
(standard, ca 17 KB/s för 44 kHz mono, liten hörbar förlust, låg CPU) eller IMA-ADPCM (ca 22 KB/s, hörbar förlust).
**Ogg Vorbis** är mycket mindre men kräver mer CPU; rekommenderas för musik, tal och långa ljud. **MP3** kostar mindre
CPU än Ogg och rekommenderas för långa stämningsljud på mobil när många komprimerade ljud spelas samtidigt. Gör mono,
högst 48 kHz, och **22 kHz för röster** [12].

För oss: korta effekter och babbelstavelser som WAV (QOA, mono, 22 kHz) – dagens `compress/mode=2` är redan QOA;
musik och lager som Ogg; om vi spelar 4 musiklager + stämning samtidigt på en svag telefon, pröva MP3 för stämningen.

---

## 5. Babbel för De edsvurna – konkret design

**Princip:** "svenskklingande nonsens". Stavelserna väljs efter vokalerna i den svenska texten (a, e, i, o, u, y, å,
ä, ö), så att en replik låter som svenska på avstånd – som Animalese med kana – men utan att försöka uttala orden.
Formantmodellen (Celeste) ger vokalkaraktären; tonhöjd, klang och tempo ger figuren.

### Regler

1. **Skrivmaskin.** `DialogBox` får en synlig del (`shown` tecken). Takt ca 45 tecken/s (justerbar). Ett tryck visar
   hela repliken och tystar babblet; nästa tryck går vidare (som i dag).
2. **En stavelse per 2–3 bokstäver** (figurens `rate`), aldrig en per bokstav – det blir maskingevär. Ny stavelse när
   en vokal visas; konsonantkluster ger en kort "tick" i figurens konsonantljud (eller ingenting).
3. **Skiljetecken:** mellanslag = ingen paus; `,` = 120 ms paus; `.` `;` `:` = 250 ms; `…`/`...` = 400 ms;
   tankstreck = 180 ms. `?` = sista stavelsen +3 halvtoner (glid uppåt); `!` = +2 halvtoner och +3 dB på frasens sista
   2 stavelser. Text inom citattecken (Ragnhilds bibelord) talas ett halvt steg lägre och 15 % långsammare.
4. **Variation:** tonhöjd ± figurens `jitter` halvtoner per stavelse; samma sampel aldrig två gånger i rad (Celeste);
   en lätt fallande linje över varje fras (svensk prosodi faller mot slutet), utom vid `?`.
5. **Tak:** högst ca 3 s babbel per replik (längre repliker babblar första och sista frasen, tyst emellan) – det är
   rytmen som säger "hen pratar", inte längden.
6. **Känsla efter tillfälle**, inte efter ord: barks för `fallen`, `alone`, svår strid = −2 halvtoner, långsammare;
   `treasure`, `rare_find`, `welcome` = +2 halvtoner, snabbare. Kan senare läsas från ett valfritt `mood` per replik.
7. **Vem som inte babblar:** berättarrutorna (`narrator`) är tysta eller får ett mjukt penn-/papperssus – tystnaden
   skiljer berättaren från figurerna. Paladinen är spelaren: babblar lågt och sparsamt (inställning: av som standard?
   – fråga VD).
8. **Volym:** −12 dB på Sfx-kanalen (eller en egen `Voice`-kanal, rekommenderas – då kan inställningarna få ett tredje
   reglage "Röster" och den som tröttnar stänger av utan att tappa effekterna).

### De tolv

`f0` = grundton i Hz, `formant` = förskjutning av formanterna (1,0 neutral; < 1 större/mörkare kropp, > 1 mindre/ljusare),
`rate` = bokstäver per stavelse, `jitter` = slumpad tonhöjd ± halvtoner.

| Figur | Röstbild | f0 | formant | Klang (källa i syntesen) | rate | jitter | Särdrag |
|---|---|---|---|---|---|---|---|
| **Paladinen** | stadig, varm, få ord | 115 | 0,95 | mjuk såg, lågpass | 3,0 | 0,5 | jämn takt, faller i slutet; sparsam |
| **Imma** | barndomsvännen, kvick och busig | 230 | 1,15 | ljus puls, lite brus | 2,0 | 2,0 | snabb, studsande, ofta uppåtglid; ibland ett litet fniss-sampel |
| **Brokk** | dvärg, grus i rösten | 85 | 0,85 | såg + subharmonisk + brus (grus) | 3,0 | 1,0 | tunga, långa stavelser; ett "hm" (nasalt m) före långa repliker |
| **Syster Alva** | varm präst | 205 | 1,05 | nästan sinus, mjuk | 2,5 | 0,8 | långa glid mellan stavelser, mjuka ansatser |
| **Jägaren Eira** | fåordig, vaksam | 190 | 1,05 | andig (mycket brus), kort | 3,0 | 0,7 | korta, avklippta stavelser; långa pauser vid komma |
| **Solveig** | eldmagiker, het i humöret | 215 | 1,10 | ljus såg | 2,0 | 1,5 | snabb; ett litet sprak (knaster) på konsonanterna |
| **Ronja Falkvind** | falkenerare | 235 | 1,12 | luftig, visselöverton | 2,5 | 1,2 | staccato; ibland en kort vissling i slutet av en fras |
| **Lirien Silversträng** | bard | 245 | 1,10 | ren, med vibrato | 2,0 | – | stavelserna kvantiseras till en pentatonisk skala – det låter som halvsång |
| **Broder Tove** | munk, lugn | 110 | 0,92 | mjuk, lite eko (rumsklang) | 3,0 | 0,3 | nästan monoton, långa stavelser, jämn rytm |
| **Hulda Mossrot** | druid, jordnära, äldre | 175 | 1,00 | lite knarr (vocal fry), lågpass | 2,5 | 1,5 | ojämn rytm, "mm" och skrockande ansatser |
| **Ragnhild Ljusdom** | domare, sträng och älskvärd | 165 | 1,00 | klar, fast ansats | 3,0 | 0,4 | exakt rytm, tydligt fallande frasslut; citat lägre och långsammare (regel 3) |
| **Sefir av Sanden** | svärdsdansare | 150 | 1,00 | varm, lätt nasal | 2,0 | 1,0 | rytmisk, nästan dansande (stavelserna på ett jämnt 3-takts-mönster) |

Personerna i borgen (samma system, färre stavelser): Mäster Gorm 95 Hz, 0,88, grov och långsam; smeden Hedda 180 Hz,
kort och kraftig ansats; Broder Alrik 125 Hz, mjuk och lite darrig (vibrato); vapenmästaren Stig 105 Hz, kort,
bjäffande; Mor Elin 200 Hz, varm och snabb; portvakten Sven 120 Hz, släpig; gravgrävaren Tor 90 Hz, hes (brus).

Kontrollera att varje par som ofta pratar i `pairs` skiljer sig i minst två av f0, klang och rytm (t.ex. Imma/Brokk,
Alva/Ragnhild – båda kyrkliga: Alva mjuk och glidande, Ragnhild fast och exakt).

---

## 6. Implementationsskiss i Godot

### a) Generera stavelserna: `tools/gen_voices.py` (numpy + soundfile, som gen_sfx.py)

Källa–filter-syntes, en mapp per figur: `assets/audio/voice/<id>/<vokal>_<n>.wav` (mono 22 050 Hz, ca 90–160 ms).

```python
# Formanter (Hz) för svenska vokaler, ungefärliga, vuxen röst: (F1, F2, F3)
VOWELS = {"a": (750, 1250, 2600), "e": (420, 2100, 2700), "i": (280, 2300, 3100), "o": (380, 750, 2500),
          "u": (310, 1650, 2300), "y": (270, 2000, 2400), "å": (450, 900, 2500), "ä": (600, 1800, 2600),
          "ö": (450, 1500, 2400)}

def syllable(f0, formant, vowel, kind, dur, rng):
    t = np.arange(int(SR * dur)) / SR
    f = f0 * (1 + 0.02 * np.sin(2 * np.pi * 5.5 * t))           # lätt vibrato
    src = glottal(f, kind, rng)                                  # såg/puls/sinus + brus + subharmonisk efter klang
    out = sum(bandpass(src, F * formant, bw=80 + F * 0.08) * g    # tre formanter, glider mot nästa vokal i 30 %
              for F, g in zip(VOWELS[vowel], (1.0, 0.6, 0.25)))
    return envelope(out, attack=0.012, release=0.04)             # mjuk ansats, inga klick
```

2 varianter per vokal (lätt olika glid) = 18 sampel per figur, plus 1–3 "extra" (Brokks hm, Immas fniss, Ronjas
vissling). Totalt ca 19 figurer × 20 sampel ≈ 380 filer, ca 0,3 MiB med QOA. Tonhöjden bakas i sampel nära
figurens f0, så att `pitch_scale` i spelet bara behöver ± några halvtoner (stora `pitch_scale` förvränger formanterna –
det är just det som gör Animalese "chipmunk", och vi vill behålla kroppen).

Röstprofilerna i `data/voices.json`, så att samma data styr både genereringen och spelet:

```json
{ "imma": {"f0": 230, "formant": 1.15, "kind": "pulse_bright", "rate": 2.0, "jitter": 2.0,
           "extras": ["giggle"], "scale": null, "volume_db": -12},
  "lirien": {"f0": 245, "formant": 1.10, "kind": "pure_vibrato", "rate": 2.0, "jitter": 0,
             "scale": [0, 2, 4, 7, 9]} }
```

### b) Spela upp: `scripts/game/babble.gd` (klass `Babble`, ingen nod-logik i texten)

```gdscript
class_name Babble
extends Node
## Babblar en replik i takt med skrivmaskinen. En instans per DialogBox-ägare (borgen, rumskartan, StoryBox).

const CPS := 45.0                       # tecken per sekund i skrivmaskinen
var _player := AudioStreamPlayer.new()
var _voice: Dictionary                  # ur data/voices.json
var _text := ""
var _shown := 0.0
var _next_syll := 0                     # index i texten där nästa stavelse får spelas
var _pause := 0.0
var _last := ""

func _ready() -> void:
	_player.bus = GameSettings.VOICE_BUS  # ny kanal "Voice" (eller SFX_BUS)
	add_child(_player)

func start(who: String, text: String, mood := 0.0) -> void:
	_voice = Voices.get_profile(who)    # tom = tyst (narrator)
	_text = text; _shown = 0.0; _next_syll = 0; _pause = 0.0

func finish() -> void:                  # trycket som visar hela repliken
	_shown = _text.length(); _player.stop()

func shown() -> int:
	return int(_shown)

func _process(delta: float) -> void:
	if _shown >= _text.length():
		return
	if _pause > 0.0:
		_pause -= delta; return
	var before := int(_shown)
	_shown = minf(_shown + CPS * delta, _text.length())
	for i in range(before, int(_shown)):
		var c := _text[i].to_lower()
		_pause = PAUSES.get(c, 0.0)      # {",": 0.12, ".": 0.25, "?": 0.25, "!": 0.25, "…": 0.4}
		if _pause > 0.0:
			_shown = i + 1; return
		if i >= _next_syll and c in "aeiouyåäö" and not _voice.is_empty():
			_play(c, i)
			_next_syll = i + int(_voice.rate)

func _play(vowel: String, i: int) -> void:
	var s := _pick(vowel)                # aldrig samma sampel två gånger i rad
	var semis := randf_range(-_voice.jitter, _voice.jitter) - 1.0 * _phrase_pos(i)  # fallande fras
	if _ends_with(i, "?"): semis += 3.0
	if _voice.scale: semis = _snap_to_scale(semis, _voice.scale)
	_player.stream = s
	_player.pitch_scale = pow(2.0, semis / 12.0)
	_player.volume_db = _voice.volume_db + (3.0 if _ends_with(i, "!") else 0.0)
	_player.play()
```

Inkoppling: `DialogBox.box()` får en parameter `shown := -1` och ritar `text.substr(0, shown)` (räkna radbrytningen på
hela texten så att orden inte hoppar mellan raderna). `base_screen` (`_conv`), `room_map_screen` (barks) och
`story_box` håller en `Babble` och anropar `start()` när repliken byts och `finish()` vid tryck om repliken inte är
färdig. Tester: en ren funktion `Babble.schedule(text, voice) -> Array[{at, vowel, semis}]` som kan testas headless
(pauser, `?`-glid, taket på 3 s, ingen upprepning) – samma idé som att stridslogiken är fri från noder.

Flaggor för skärmdumpar och provlyssning: `--babble=<figur>` spelar en provreplik i borgen; `--no-babble`.
Inställningsrutan (`SettingsBox`): reglaget **Röster** (0 % = av).

### c) Senare: riktiga utrop ovanpå

`data/voices.json` får `"greet": ["imma_greet_1", …]`; filerna heter efter replikernas id-system
(`assets/audio/voice/imma/greet_1.ogg`). När ett samtal öppnas spelas ett utrop i stället för de första
stavelserna, sedan tar babblet över. Inget i `dialog.json` behöver ändras.

---

## 7. Öppna frågor till VD

1. Ska Paladinen babbla (spelarens figur), eller vara tyst som i Undertale?
2. Skrivmaskinstext i borgen: välkommet, eller ska repliken fortsätta synas direkt med en kort babbelstöt (~1 s)?
3. Ett eget reglage "Röster" i inställningarna?
4. Värt att testa tre Imma-utrop i ElevenLabs/Azure mot babblet, när babblet finns?

---

## Källor

1. Nookipedia, "Animalese": https://nookipedia.com/wiki/Animalese – samt `animalese-tts` (https://cdn.jsdelivr.net/npm/animalese-tts@1.1.3/readme.md) och Rust-craten https://docs.rs/animalese
2. GOODLANDS devlog, "How to: Animal Crossing Dialogue Sounds": https://geolojosh.itch.io/goodlands/devlog/314373/how-to-animal-crossing-dialogue-sounds ; Springbound devlog 4: https://brycetown.substack.com/p/springbound-devlog-4-making-critters-talk
3. RPG Maker MZ Dialogue Bleep (teknikbeskrivning): https://winterbitestudios.itch.io/plugin-rpg-maker-mz-dialogue-bleep ; fanprojekt om Undertales röstblips: https://turbowarp.org/113618749 (ingen officiell källa om Undertales implementation hittades)
4. Kevin Regamey (PowerUpAudio), tråd om Celestes dialogljud: https://threadreaderapp.com/scrolly/1416483583053602816
5. TheGamer, "Celeste sound designer reveals how the game's dialogue audio was created": https://www.thegamer.com/celeste-sound-designer-reveals-how-the-games-dialogue-audio-was-created/
6. Wikipedia, "Banjo & Kazooie" (mumble-speak, Mumbo Jumbo): https://en.wikipedia.org/wiki/Banjo_%26_Kazooie
7. GDC Vault, "Breathing Life into Greek Myth: The Dialogue of Hades": https://gdcvault.com/play/1026975/Breathing-Life-into-Greek-Myth ; Inven Global-intervju: https://www.invenglobal.com/datalab/articles/14783/supergiant-games-how-indie-developers-made-goty-hades
8. Voquent, "Hades voice actors": https://www.voquent.com/blog/hades-voice-actors/
9. Om Wayne June och Darkest Dungeon: https://mein-mmo.de/en/one-of-the-darkest-voices-in-gaming-is-silenced-forever,1222622 ; https://multiplayer.it/notizie/darkest-dungeon-non-usera-lia-per-ricreare-la-voce-dello-scomparso-wayne-june-nonostante-il-suo-consenso.html ; recension: https://gamegeeker.com/games/darkest-dungeon-262060/review?market=GB
10. GDSAM-plugin för Godot 4.1+: https://github.com/deadpixelsociety/gdsam-plugin
11. AudioStreamGenerator-guide: https://gamedevacademy.org/audiostreamgenerator-in-godot-complete-guide/
12. Godot-dokumentationen, "Importing audio samples": https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_audio_samples.html
13. Piper, modellkortet för sv_SE-nst (dataset CC0): https://huggingface.co/rhasspy/piper-voices/blob/main/sv/sv_SE/nst/medium/MODEL_CARD
14. Azure Speech, prissida (sv-se): https://azure.microsoft.com/sv-se/pricing/details/speech/ ; andrahandsuppgifter: https://cloudprice.net/models/azure-neural , https://speechactors.com/article/?p=3863
15. ElevenLabs billing-dokumentation: https://elevenlabs.io/docs/overview/administration/billing.md ; https://dupple.com/learn/is-elevenlabs-free ; https://app.cinevva.com/guides/ai-voice-acting-games ; https://smallest.ai/blog/elevenlabs-alternatives-for-commercial-use-licensing-checklist-and-safe-workflows
16. Google Play, AI-genererat innehåll: https://support.google.com/googleplay/android-developer/answer/14094294 ; analys: https://www.revera.legal/?p=3557 ; SAG-AFTRA 2025: https://hitmarker.net/news/sag-aftra-approves-2025-video-game-agreement-ending-strike-amid-concerns-about-use-of-ai-1473806
17. Godot 4.3 release: https://godotengine.org/releases/4.3/
18. Uhiyama Lab, "Building Adaptive Music in Godot with AudioStreamInteractive": https://uhiyama-lab.com/en/notes/godot/adaptive-music-system/
19. Godot-klassreferens, AudioStreamInteractive: https://docs.godotengine.org/en/stable/classes/class_audiostreaminteractive.html
20. Godot-forumet, Interactive inuti Synchronized: https://forum.godotengine.org/t/help-combining-audiostreaminteractive-and-audiostreamsynchronized/100519
