# Ljud och musik – mappning

Inkopplat i 0.17.2. Den här filen säger var varje ljud hör hemma. Källor och licenser: `ASSETS_LICENSE.md`. Allt byggs om med
`tools/gen_audio.py` (kräver numpy och soundfile, se filhuvudet).

Alla nya ljud ligger i **mappar** (`assets/audio/<namn>/`), så `sfx.play("<namn>")` slumpar mellan
varianterna. Totalt cirka 0,9 MiB ogg Vorbis. Kontrollera inkopplingen med `-- --log-sfx`.

**Så är det inkopplat:** `Run.audio` (en `Sfx` i autoloaden) spelar musiken och menyljuden.
Basens skärmar startar `music_base` och ger `ui_tap` efter varje tryck som inte redan lät; `Run.go()`,
`save(sound)`, `start_run()` m.fl. ger de särskilda menyljuden. Striden väljer musik och stämning efter
Realm och boss (`_start_music`), och spelar förmågans `cue` (eller vapnets/skolans ljud, `_cue`) när
handlingen börjar och `sound` när den träffar. Troféljudet spelas i `Run.battle_finished()` efter den
finaste trofén i erbjudandet. Natur-ljuden finns men exporteras inte förrän någon förmåga använder dem.

## Musik (`assets/audio/music/`)

Mono 22 kHz (stämningarna 16 kHz och 16 s långa), låg bitrate, 27–34 s långa loopar. Efterklangen är vikt tillbaka till början, så de loopar
sömlöst om man sätter `loop = true` på `AudioStreamOggVorbis` (i koden eller i importinställningen).

| Fil | Karaktär | Var |
|---|---|---|
| `music_base.ogg` | D-dur, 72 bpm, harpa, stråkar, flöjt – lugn och hoppfull | Basen (alla platser: Kryptporten, Övningsgården, Smeden, Edsaltaret, Biblioteket, Makron) och lägret |
| `music_crypt.ogg` | D-moll, 60 bpm, bordun, cello, gravklocka, avlägsen puka – dov | Strider i Benkryptan (våning 0–1) |
| `music_chapel.ogg` | E-frygisk, orgel och kör, tritonus, svajande "gammalt band" – sakral och förvriden | Strider i Det fördärvade kapellet (våning 0–1) |
| `music_mountain.ogg` (byggd, inte inkopplad) | A-dorisk polska i långsam 3/4 (84 bpm, 16 takter, 34 s): tung etta med en djup trumma, dragen tvåa, tom trea. Bordun i kvint (A–E) som från en nyckelharpa, låga stråkar, en egen spelmansfras med förslag i takt 5–12 och en kulning långt bort i takt 13. Tungt, kallt och gammalt; inget ur Grieg, inga körer | Strider på Trollberget (`docs/plan/trollens-realm.md` §12). Bossen (Bergakungen) använder `music_boss.ogg` |
| `music_boss.ogg` | C-moll, 132 bpm, ostinato, pukor, mässing, kör – intensiv | Bosstrider (Benfursten, Den fallne biskopen), och i Övningsgården mot en boss |

Förslag på inkoppling: en egen `_music`-spelare i `sfx.gd` med `play_music(name, volume_db := -14.0)`
som korstonar (1–1,5 s) när låten byts och inte startar om samma låt. Musiken ska ligga under ljuden:
börja kring −14 dB och stämningen kring −12 dB. Sänk musiken (−6 dB, 0,3 s) medan segerfanfaren spelas.

## Ambiens

| Fil | Var |
|---|---|
| `ambience_crypt.wav` (finns) | Benkryptan, som nu |
| `ambience_chapel/` (24 s loop) | Det fördärvade kapellet: avlägsen orgelton, viskningar, knarr och droppar |
| `ambience_home.wav` (22 s loop, 0.24) | Borgen: härden som sprakar, brus i skorstenen och smedens städ långt bort (`tools/gen_home_ambience.py`). Tonas ut när man lämnar borgen (`Sfx.stop_ambience`). |

| `ambience_mountain/` (24 s loop, Trollberget) | Vind över sten med byar, droppar i ett schakt, berget som andas (mycket lågt mullrande två gånger per loop), sten som gnids långt bort, ett litet ras och tre tunga steg långt inne i berget. Ingen melodi (inte Grieg). `docs/plan/trollens-realm.md` §12 |
| `mountain_call/` (2 varianter, ~9,5 s, engångsljud) | Kulning långt bort i dalen (vallkullan kallar hem korna; egna fraser, ingen känd melodi). Ligger inte i loopen, där den skulle höras var 24:e sekund. Tänkt att spelas **sällan**, t.ex. en gång per strid med 25 % chans efter 8–20 s, kring −14 dB |

`start_ambience()` sätter bara loop på WAV. För ogg: `if s is AudioStreamOggVorbis: s = s.duplicate(); s.loop = true`.

## Strid: handlingar

I dag spelas inget kastljud alls (`unit_model.start_cast_sound()` anropas inte och `cast_*.wav` används
inte), bara träffljudet. Hjälpregel: **kastljudet** spelas när figuren svingar eller kastar, **träffljudet** (`sound` i
`abilities.json`) när det träffar. Vapentyp efter `visual.grip_r`/`grip_l`.

| Ljud | Varianter | Förslag |
|---|---|---|
| `atk_sword` | 3 | Anfall med svärd: Paladinen (`strike`, Longsword), `bone_slash`, `knight_cleave`, Benfursten (Greatsword). Ersätter `k_hero_hit` som `sound` |
| `atk_axe` | 3 | Anfall med yxa: Brokk (`axe_chop`, Greataxe), glödskelettet |
| `atk_blunt` | 3 | Anfall med stav/klubba/gissel: Alva (Mace), Solveig (Staff), gravprästen, gravväktaren, `penitent_flail`, `shield_bash` |
| `bow_shot` | 3 | Bågen spänns och släpps: Eira, skelettbågskytten (vid avfyrning) |
| `arrow_hit` | 3 | Pilen träffar: `sound` för `arrow`, `bone_arrow`, `aimed_shot`, `arrow_rain` |
| `spell_holy` | 2 | Kast av helig besvärjelse (`school: holy`): `holy_smite`, `holy_bolt`, `judgement`, `holy_shield` |
| `spell_fire` | 2 | Kast av eld (`school: fire`): `fire_bolt`, `flame_wave`, `fireball`, `ember_*` |
| `fire_hit` | 2 | Träffljud för eld. Ersätter `pyro_impact` |
| `spell_shadow` | 2 | Kast av skugga (`school: shadow`): `shadow_bolt`, `lich_*`, `witch_*`, `bishop_*`, `dark_sermon`, `wraith_claw` |
| `shadow_hit` | 2 | Träffljud för skugga. Ersätter `volley_impact` |
| `spell_nature` | 2 | Natur (finns ingen ännu – till framtida druid/jägarförmågor, t.ex. `hunters_mark`) |
| `nature_hit` | 2 | Träff för natur |
| `heal_light` | 2 | Helning: `healing_light`, `renew`, `holy_bolt` på allierad, helande artefakter. Ersätter `heal.wav` |
| `defend` | 2 | Försvara (`defend`, `stone_wall`, `knight_stand`). Ersätter `k_shield_wall` för Försvara |
| `provoke` | 2 | Provocera (`provoke`, `warden_provoke`) – sköldslag och stridshorn |

`k_shield_wall` passar fortfarande för `holy_shield` (barriär). Behåll `k_boss_hit`, `k_hero_crit`,
`bone_crush` och `death` – de är redan inspelade och tunga.

## Trollberget (byggda, inte inkopplade)

Syntes i `tools/gen_audio.py` (`ambience_mountain`, `mountain_call`, `troll_smash`, `troll_growl`, `stone_throw`,
`stone_land`). Bygg bara dessa, utan Kenney-paketet: `python tools/gen_audio.py --berget` (i en venv med numpy och
soundfile, se filhuvudet). En full körning bygger dem sist, så att de andra ljuden inte ändras.

| Ljud | Varianter | Förslag |
|---|---|---|
| `troll_smash` | 3 | Tungt klubbslag: luften, en duns genom marken, sten som spricker och grus. `sound` för `troll_club_swing`, `ground_slam`, `toll_strike`, `mountain_club`, `troll_ladle` (i dag `bone_crush`) |
| `troll_growl` | 2 | Morrande andning, lågt och skrovligt, med ett inandat andetag. `cue` för trollens förmågor (när de börjar), eller när ett troll vredgas; `mountain_wrath` |
| `stone_throw` | 2 | Ett stönande tag, skrap när stenen lossnar och ett tungt sus. `cue` för Kyrkkastarens `boulder_throw` och `moss_throw` |
| `stone_land` | 2 | Stenen slår ned: krasch, djup duns, grus som rullar ut. `sound` för `boulder_throw`, `moss_throw`, `bridge_toll` |

Kvar ur §12: vaggvisans nynnande, Bergsråets baklänges kulning, `bell_toll` och en bossvariant av musiken (samma
bordun, trumman dubbelt så tät).

**Så kopplas stämningen in** (görs på Realmens gren): `_start_music()` i `scripts/battle/battle.gd` väljer i dag mellan
kryptan och kapellet med en `if`. Förslag: `"ambience": "ambience_mountain"` (och gärna `"ambience_db": -11.0`) i
Realmens post i `realms.json`, och `_start_music()` läser `data.realms[realm].get("ambience", "ambience_crypt")`.
Ogg-filen loopas av `start_ambience()`. Musiken på samma sätt: `"music": "music_mountain"` i Realmens post,
och `_start_music()` spelar `data.realms[realm].get("music", "music_crypt")` i stället för valet mellan kapellet och
kryptan (bossar behåller `music_boss`). `play_music()` loopar ogg som de andra spåren. Kör `godot --headless --path . --import` en gång så att `.import`-filerna skapas.

## Strid: händelser

| Ljud | Händelse |
|---|---|
| `trophy_common` | Trofé från ett vanligt monster (lägret/strid vunnen, `rarity: common`) |
| `trophy_elite` | Trofé från ett elitmonster |
| `trophy_boss` | Bossens trofé (regelbrytare) |
| `elite_appears` | En elitvariant syns i mötet (vid `battle_start`, eller när fienden presenteras) |
| `boss_appears` | Bossen syns (Benfursten, Den fallne biskopen) – före bossmusiken |
| `macro_nomatch` | Auto stannar för att ingen makrorad passar (i dag `k_error`, som är för skarpt) |
| `jingle_victory` | Seger. Ersätter `victory.wav` |
| `jingle_defeat` | Förlust. Ersätter `defeat.wav` |

## Rumsögonblick (0.18, inte inkopplade än)

| Ljud | Var |
|---|---|
| `room_door` | En dörr öppnas till nästa rum (knarr, drag, duns mot väggen; 1,9 s) |
| `room_chest` | En kista öppnas (spänne, lock, mynt och ett litet skimmer; 2,2 s) |
| `room_lock` | Ett hänglås låses upp (två nyckelklick och bygeln som släpper; 1,0 s) |

## Menyer och basen

| Ljud | Var |
|---|---|
| `ui_tap` | Varje knapptryck (lämpligt i `tap_screen.gd` vid släpp) |
| `ui_back` | Tillbaka / stäng / hem till basen |
| `ui_confirm` | Bekräfta: köp perk, välj Ed, välj djup/Realm, starta körning |
| `ui_toggle` | Växla: Auto, 1×/2×, perk-nivåer, makrorad på/av |
| `ui_page` | Biblioteket och makroredigeraren (bläddra) |
| `ui_coins` | Silver ges eller dras (Smeden, efter strid) |
| `ui_forge` | Smeden smider en artefakt (spela 2–3 gånger med 0,25 s mellanrum som hammarslag) |
| `ui_door` | Gå in genom Kryptporten |

Föreslagna nivåer: `ui_*` −10 dB, troféer −4 dB, stingers −2 dB, handlingar som i dag (−6/−2 vid krit).

## Gamla ljud som inte längre exporteras (exclude_filter)

`heal.wav`, `pyro_impact.wav`, `volley_impact.wav`, `victory.wav`, `defeat.wav` (syntetiserade
platshållare från WoW-prototypen). Redan oanvända i dag och kan tas bort direkt (cirka 0,4 MiB, mer
än hälften av de nya ljudens storlek): `cast_holy.wav`, `cast_fire.wav`, `cast_shadow.wav`,
`cast_frost.wav`, `frost_impact.wav`, `kick.wav`, `interrupt.wav`, `k_interrupt/`, `k_kick/`.
