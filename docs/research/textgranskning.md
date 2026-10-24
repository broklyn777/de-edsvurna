# Textgranskning (test-0.30, 89a4115, 2026-10-24)

Det här är bara en läsning, ingen text är ändrad. Granskat: all spelartext i `data/*.json` (dialog, intro, help, traits, abilities,
auras, enemies, encounters, realms, objects, world_events, vows, floor_rules, materials, titles, personalities, artifacts,
oaths) och de svenska strängarna i `scripts/` och `src/`. Måttstockar: `docs/ordlista.md`, tonregeln (följeslagarna och
Paladinen låter aldrig ockulta; troféer är föremål eller lärdomar, aldrig kroppsdelar, eder, pakter eller mottagen kraft)
och Siralims termer. **Kontrollera** betyder att jag har läst koden men inte provat i spelet.

## Topp 10

1. **Broder Alrik förklarar troféer som kroppsdelar och mottagen kraft.** Repliken säger "ett ben, en ring, en flisa. Den
   som bär det får monstrets egenskap." Den står på tre ställen och är spelarens första möte med troféerna. Den strider mot
   tonregeln och mot lärdomarna (`lesson`, "{bärare} har lärt sig …").
2. **Solveig har två förmågor med samma namn.** Både `fire_bolt` (hennes anfall) och `fireball` (hennes förmåga) heter
   "Eldklot", så makroraden och knappen går inte att skilja åt.
3. **Provocera beskrivs fel.** Förmågan säger "du tar 30 % mer skada", men auran ger −35 % Defense (`defense_mult` 0,65). Så
   står det också i auran, ordlistan och Siralim.
4. **Våningsregeln "Inga bönder"** betyder ingenting på svenska. Regeln är "No Guard", att ingen kan Försvara eller
   Provocera. Namnet syns i Inspect, i stridens felrad och i makroförklaringen.
5. **Engelska i en kallkärna.** Väktarens kall säger "träffas av en attack eller spell".
6. **Resistent beskrivs fel.** Texten säger "Debuffar har halv effekt (Märkt, Brinner …)". Koden mildrar bara statusarna som
   har en Resistant-version (Tystad, Hånad, Sover, Snärjd, Frusen, Blöder, Förstenad), och Märkt och Brinner verkar fullt.
7. **"Ed" och "kall" blandas.** Altaret visar "LÅNA EN PERK FRÅN EN ANNAN ED" (det heter kall sedan 0.18). Borgens station
   heter "Kallets kapell", men uppdraget, hjälpen och ordlistan säger "Kallets altare".
8. **Benfurstens bosskort** har ett genusfel: "Väcker en fallen skelett". Det ska vara "ett fallet skelett".
9. **Personligheten Eftertänksam** säger "innan **hon** handlar", men den kan sitta på vem som helst, till exempel Brokk eller
   Paladinen.
10. **"Charge", "laddning" och "styrka" står för olika saker på olika ställen.** Krönikan säger "en laddning mindre" och "en
    laddning extra" där kartan och hjälpen säger Charge. Daggnätet och glasfönstret säger "+15 % styrka", vilket blandas ihop
    med statusen Styrka (nästa anfall +30 %).

## Hela listan

Sorterad efter allvar. Hög: fel information, tonregeln, engelska eller samma namn på två saker. Medel: inkonsekventa termer
och grammatik. Låg: stil, upprepningar och sådant att se över i bild.

| # | Allvar | Fil | Id / nyckel | Nuvarande | Förslag | Varför |
|---|---|---|---|---|---|---|
| 1 | Hög | dialog.json, intro.json | `people.alrik.trophies.0`, `steps.4.at.alrik.3` | "Varje monster du besegrar kan lämna något efter sig – ett ben, en ring, en flisa. Den som bär det får monstrets egenskap." | "Varje monster du besegrar kan lämna något efter sig – en ring, en klinga, ett radband. Den som bär det minns hur monstret slogs och lär sig något av det." | Tonregeln: inga kroppsdelar och ingen mottagen kraft. Det är spelarens första förklaring av troféer. |
| 2 | Hög | help.json | `entries.trophies.text.0` | "Besegrade monster lämnar ibland en trofé. Den som bär den får monstrets egenskap." | "… Den som bär den har lärt sig något av monstret: dess egenskap." | Som ovan; lärdomen (VD 2026-10-23) bör synas redan i hjälpen. |
| 3 | Hög | abilities.json | `fire_bolt.name`, `fireball.name` | "Eldklot" / "Eldklot" | `fire_bolt` "Eldgnista" eller "Eldpil"; `fireball` "Eldklot" | Båda tillhör Solveig, så makroraderna och knapparna ser likadana ut. |
| 4 | Hög | abilities.json | `provoke.text` | "… men du tar 30 % mer skada." | "… men din Defense sjunker 35 %." | Auran `provoke` har `defense_mult` 0,65; auran, ordlistan och Siralim säger 35 % Defense. |
| 5 | Hög | floor_rules.json (+ battle.gd:23, macro_runner.gd:400) | `no_guard.name` | "Inga bönder" | "Ingen gard" (eller "Utan gard") | "Bönder" betyder ingenting här; regeln är att ingen kan Försvara eller Provocera. |
| 6 | Hög | traits.json | `oath_ward.text` | "träffas av en attack eller spell" | "träffas av ett anfall eller en besvärjelse" | Engelska i spelets text. |
| 7 | Hög | traits.json | `resistant.text` | "Debuffar har halv effekt (Märkt, Brinner …)." | "Vissa debuffar biter sämre: Tystad, Hånad, Sover, Snärjd, Frusen, Blöder och Förstenad. Andra verkar fullt." | Koden (`combat_sim.gd` 517–747, 1428–1497) mildrar bara statusarna med en Resistant-version, så exemplen i texten är fel. |
| 8 | Hög | altar_screen.gd:123 | rubrik | "LÅNA EN PERK FRÅN EN ANNAN ED" | "LÅNA EN PERK FRÅN ETT ANNAT KALL" | Det heter kall sedan 0.18 (ordlistan), och raderna 183 och 186 i samma fil säger "kall". |
| 9 | Hög | enemies.json | `bone_lich.boss_text` | "Väcker en fallen skelett var tredje tur" | "Väcker ett fallet skelett var tredje tur" | Skelett är ett ett-ord. Felet syns på bosskortet. |
| 10 | Hög | personalities.json | `eftertanksam.text` | "Väger varje ord innan hon handlar." | "Väger varje ord innan handling." | Personligheten kan sitta på en hjälte av vilket kön som helst. |
| 11 | Hög | traits.json | `pact_blade.name` | "Den brutna paktkniven" | "Den brutna blodkniven" eller "Blodsvurens kniv" | Tonregeln: ingen pakt i ett troféns namn, även om den är bruten. Lärdomen själv är bra. |
| 12 | Hög | abilities.json / auras.json | `renew` (förmåga) och `renew` (aura) | Förmågan "Förnyelse" ger **Läkning** (25 % liv per tur), men auran som heter "Förnyelse" säger "70 % av kastarens Intelligence" | Döp om förmågan till t.ex. "Läkande hand", eller auran om den inte används | Två olika effekter med samma namn; Inspect och förmågan säger olika saker. **Kontrollera** om auran `renew` används alls. |
| 13 | Hög | abilities.json / auras.json | `holy_shield` | Förmågan "Helig sköld" ger Beskyddad (−50 %), men auran "Helig sköld" (Pandemonium, `run_state.gd:911`) ger −40 % | Döp om Pandemoniums aura till "Välsignad sköld", eller låt Pandemonium ge Beskyddad | Samma namn, två siffror. |
| 14 | Medel | dialog.json | `chronicle.lines.105`, `.123` | "en laddning mindre", "en laddning extra" | "en Charge mindre", "en Charge extra" | `world.cost_map.chapel` och hjälpen säger Charge; "laddning" var förr namnet på Glöd. |
| 15 | Medel | objects.json, run_state.gd:1036 | `dew_web.results.pull`, glasfönstret | "beredd (+15 % styrka)" | "beredd (+15 % på alla stats)" eller "(15 % starkare)" | Krockar med statusen Styrka (nästa anfall +30 %). |
| 16 | Medel | dialog.json, intro.json | `stations.altar.name` | "Kallets kapell" | "Kallets altare" | `steps.0.quest`, hjälpen, ordlistan och CLAUDE.md säger "Kallets altare". |
| 17 | Medel | dialog.json | `ragnhild.rescue.2`, `.cave.2`, `.campfire.2`, `.alone.2`, `inn.ragnhild.welcome.0` | "Herren …" på fyra ställen, "HERREN …" på ett | "HERREN" där 1917 års text har det (Ps 23:1, 121:2, 121:7) | 1917 skriver Gudsnamnet med versaler i Gamla testamentet; `welcome.0` gör det redan. **Kontrollera** ordagrant mot Wikisource, som `refs_note` säger. |
| 18 | Medel | dialog.json | `inn.ragnhild.welcome.0`, `inn.ragnhild.bored.0` | Bibelord med ”…” | »…« för bibelord, som alla Ragnhilds andra | Två olika citattecken för samma sak. |
| 19 | Medel | dialog.json | `chronicle.lines.96` och `living_map.gorm.warn.0`; `.98` och `living_map.imma.wake.0`; `.100` och `living_map.gorm.calm_twisted.0` | Ordagrant samma rad | Skriv om krönikans version eller ta bort den | Båda kan visas efter samma hemkomst ("Medan ni var borta" och kartans replik). **Kontrollera** i `Chronicle.PRIO`. |
| 20 | Medel | dialog.json | `chronicle.lines.37` och `.99` | Båda börjar "Den svärtade är slagen." | Byt början på den ena | Två talare säger samma inledning om samma händelse. |
| 21 | Medel | dialog.json | `chronicle.lines.75` mot `.104`, `world.ongoing.2`, `world.cost_on.crypt` | "Benfolket" / "benfolket" | Alltid "Benfolket" | Familjens namn (ordlistan); "Kultens folk" och "Spindelfolket" är redan konsekventa. |
| 22 | Medel | enemies.json (+ ordlistan) | `snare_spider.elite.name` | "Silkesnärjaren" | "Silkessnärjaren" | Silkes + snärjare. Som det står nu läses det "silke-snärjaren". |
| 23 | Medel | traits.json | `knight_riposte.text` | "Medan den Fallne riddaren …" | "Medan Den fallne riddaren …" (eller "den fallna riddaren") | Ordlistan och `fallen_oath.lesson` skriver "Den fallne riddaren", och fiendens namn är "Fallen riddare". |
| 24 | Medel | help.json | `entries.room_map`, `entries.living_map` mot de andra | "ni" i två rutor, "du" i resten | Välj ett. Förslag: "du" i hjälpen, "ni" i repliker till sällskapet | Rutorna läses i handboken efter varandra. |
| 25 | Medel | help.json, room_map_screen.gd, dialog.json | Realm Quest | "uppdrag", "quest" och "questen" om samma sak | "Realm Quest" i rubriken och "questen" i löptext, som ordlistan och kartan; "uppdrag" bara för introts småuppdrag | `realm_quest.text.0` säger "ett uppdrag … det låser trappan", medan grottan säger "Questen är inte klar". |
| 26 | Medel | help.json | `entries.disciples.text.0` | "på fångrutorna i grottan" | Behåll "fångrutorna" och rätta ordlistan ("Fånge-ruta") | "Fångruta" är bättre svenska; ordlistan bör följa. |
| 27 | Medel | artifacts.json, traits.json | `helm.stat_text` m.fl. | "+5 % Health", men "max liv" i alla egenskaper | Bestäm: "Health" bara som stat-etikett (som originalet), "liv" i löptext | Ordlistan säger båda ("Liv / Attack …" och "Spelets text använder de engelska namnen"). |
| 28 | Medel | auras.json, hero_screen.gd:265 | `stone.text`, hjältebladet | "kan inte undvika eller krita"; "fler krittar" | "kan inte undvika eller göra kritiska träffar"; "fler kritiska träffar" | Slangverb och en felstavad pluralform på en skärm som annars förklarar noga. |
| 29 | Medel | auras.json | `warded` "Skyddad" mot `protected` "Beskyddad" | −25 % / −50 % | Byt `warded` till t.ex. "Skärmad" eller "Värnad" | Nästan samma ord med olika siffror; helgedomen erbjuder Skyddad. |
| 30 | Medel | titles.json | `bone_trapper.name` | "Benfurstens fälla" | "Benfurstens fall" eller "Benfurstens plåga" | Titeln är till den som fällt honom tre gånger, men "fälla" läses som att Paladinen är hans fälla för andra. |
| 31 | Medel | traits.json | `spider_snare.text` | "Bettet snärjer målet i 2 turer (25 %)." | "Bettet har 25 % chans att snärja målet i 2 turer." | Det framgår inte vad 25 % gäller. |
| 32 | Medel | dialog.json | `barks.solveig.elite.1` | "De kommer önska att någon öppnat ett fönster." | "De kommer att önska att någon hade öppnat ett fönster." | "Komma att" behöver "att" i skrift. |
| 33 | Medel | objects.json | `silk_trail.text` | "ett mot de som släpade" | "ett mot dem som släpade" | Objektsform. |
| 34 | Medel | library_screen.gd:76 | inledningen | "fler på djupare och instabilare våningar" | "fler på djupare djup och högre instabilitet" | "Instabilare" finns inte, och "våningar" är fel ord (djup och instabilitet väljs per nedstigning). |
| 35 | Medel | name_entry.gd:10 | frågan | "Vad heter du, edsvurne?" | Fråga VD: "edsvurna" (könsneutralt i vokativ, och spelets titel) | "-e" är den maskulina formen; Paladinen är "hen" i ordlistan. Bara en fråga, inget fel om VD vill ha det så. |
| 36 | Medel | dialog.json | `people.hedda.greet.1` och `.idle.2` | "Rör inte städet." två gånger i samma samtal | Byt hälsningen, t.ex. "Jaså, du igen. Torka fötterna." | Hälsning och vardagsreplik visas efter varandra. |
| 37 | Medel | dialog.json | `people.sven.greet.2` och `.idle.2` (+ `intro steps.6.at.sven.0`) | "Gå försiktigt" i båda | Byt hälsningen | Som ovan. |
| 38 | Medel | dialog.json | `people.elin.greet.2` och `.idle.2` | "Soppan står på." / "Soppan är varm …" | Byt den ena | Som ovan. |
| 39 | Låg | dialog.json, intro.json | barks och intro | "ner" (Alva, Eira, Imma, Tove) och "ned" (Gorm, hjälpen, UI) | "ned" i berättar- och UI-text; "ner" får stå i talspråk | Bara konsekvens; båda är rätt. |
| 40 | Låg | traits.json | `phantasm.lesson` | "upprepade samma ord tills de fick makt" | "upprepade samma slag tills det satt" | Lärdomen själv är bra, men "ord som får makt" låter som besvärjelsekonst. |
| 41 | Låg | traits.json | `surprise.lesson` | "lärt sig att höra varslet" | "lärt sig att höra faran först" | "Varsel" ligger nära det ockulta. |
| 42 | Låg | traits.json | `devour_maw.lesson` | "lärt sig att ta kraft ur ett säkert grepp" | "lärt sig att ett säkert grepp ger styrka" | Ligger nära "mottagen kraft". |
| 43 | Låg | objects.json | `hourglass.options.0.label`, `.text` | "OFFRA EN CHARGE", "om den får lite kraft" | "GE EN CHARGE", "om någon vänder det med en Charge" | "Offra" klingar av ritual hos en paladin. |
| 44 | Låg | enemies.json | `wraith.elite.name` | "Banshee" | "Klagekvinnan" eller "Bansheen" | Det enda engelska lånordet bland fiendernas namn. |
| 45 | Låg | materials.json | `amber_bronze.name` | "Bronsbärnsten" | "Brons bärnsten" eller "Bronsfärgad bärnsten" | De andra nio heter "X bärnsten". |
| 46 | Låg | traits.json | lärdomarna | "har lärt sig" (de flesta) och "lärde sig" (ett tiotal) | "har lärt sig" överallt | Raden står under varandra i Biblioteket. |
| 47 | Låg | traits.json | `runner_sinew.lesson` | "lärt sig hans första steg" | "lärt sig dess första steg" | Monstren är annars "den" (Skramlaren, Kistbäraren); bara de namngivna bossarna är "han". |
| 48 | Låg | traits.json, auras.json | `troll_lullaby`, `grey_shawl` mot resten | "somnar en tur" | "somnar i 1 tur" | Resten skriver "i 1 tur". |
| 49 | Låg | traits.json | `warden_helm`, `salted_earth`, `kalles_club` m.fl. | "Försvarar"/"Provocerar" med versal mitt i meningen, och "försvarar sig" med gemen i andra | Versal bara när det är handlingens namn ("väljer Försvara"); annars gemen | Små skillnader, men egenskaperna läses i bredd. |
| 50 | Låg | encounters.json | `chapel_1a.name` | "Botgångens gång" | "Botgången" | Dubbelt "gång". |
| 51 | Låg | macro_runner.gd:298, 300 | villkor | "minst %d gång(er)" | Böj efter talet, som `battle_summary.gd:121` redan gör | Syns i makroredigeraren. |
| 52 | Låg | base_screen.gd:676 och dialog.json `stations.library.options.4` | val hos Alrik | "Skriv om ditt namn …" / "Skriv om mitt namn …" | "mitt" båda (valet är spelarens ord) | Två versioner av samma val. |
| 53 | Låg | dialog.json | `nothing` | "Avsluta samtalet" (koden har "Ingenting just nu" som standard) | Ingen ändring i spelet; rätta ordlistan och CLAUDE.md | Dokumentationen följer inte datan. |
| 54 | Låg | dialog.json | `world.merchant.greet.1` | "Det glömmer jag inte, och inte mina priser heller: halva, för er." | "Det glömmer jag inte. För er: halva priset." | Meningen säger nu att han inte glömmer sina priser. |
| 55 | Låg | dialog.json | `barks.imma.hard_fight.0` | "Jag andades inte på hela striden." | "Jag andades inte under hela striden." | Prepositionen. |
| 56 | Låg | dialog.json | `living_map.quiet.0`, `.3`, `.6` | "X har varit tyst länge. Det brukar inte betyda något gott." tre gånger | Variera två av dem | Bara Realmen byts ut. |
| 57 | Låg | smith_screen.gd:647–648 | förrådets tomtext | "… skattkammare, portaler och hos bossar" | Ta bort "portaler" om grottan inte har några | Portalen var ett rum på 0.18:s rumskarta. **Kontrollera** `Forge.FINDS`. |
| 58 | Låg | abilities.json, traits.json | förmåga och egenskap med samma namn | "Flockbett", "Klockslaget", "Mässan", "Grumlad välsignelse", "Dimslöja", "Stenmur" | Lämna, eller ge förmågan ett eget namn | Inte fel, men i Inspect blir det oklart om det som slog till var förmågan eller egenskapen. |
| 59 | Låg | layout | långa rader | `help.room_map.text.1` (186 tecken), `help.macros.text.2` (184), `room_map_screen.gd:793` (elitvarningen, ~190), `world.pilgrim_rumour.1` (166), `chronicle.lines.97/112/114/126` (~147) | Se över i 1280×720 och telefonens bredd (`--resolution 1560x720`) | Längst i sitt slag; kan bli fyra rader eller mer i rutan. Inte provat i bild. |
| 60 | Låg | ordlistan | flera rader | Smeden "100 silver (byta 40)", Silver "25/35/50 per strid", Djup "+8 %" | Uppdatera: 160 / 60, våningens belöning, 3 % (0.30.33) | Utanför spelet, men ordlistan är måttstocken för nästa granskning. |

## Det som är bra och bör lämnas orört

- Ragnhilds bibelord har konsekvent »…« (utom de tre ovan), och tonen håller: sträng och varm, aldrig spydig mot tron.
- Lärdomarna (`lesson`) följer nästan alla mönstret "Monstret gjorde X. {bärare} har lärt sig Y" utan kraftöverföring. #40–42 är
  de enda gränsfallen.
- Följeslagarnas röster är tydligt olika (Brokks sköld, Eiras spår, Sefirs mantel, Toves klosterlärare). Jag hittade inga
  upprepningar mellan dem.
- Fiendernas ondska (svart mässa, Blodpakt, Häxa, Ockultist) är tydligt fiendens, som minnet om tonen säger.
