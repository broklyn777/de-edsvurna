# Provspel 0.30.14-test (grenen test-0.30, 5cab097)

Provspelat 2026-10-23 med spelets egna flaggor, skärmdumpar i 1280×720 och 1560×720 (telefonbredd), och botarna
(`BALANS=grotta`, `BALANS=forsta`). Ingen kod ändrad. Skärmdumparna ligger i
`/private/tmp/claude-501/-Users-bjornjansson-Desktop-CodeVibe26-rpg007--claude-worktrees-rum-3d-a91c58/1886a707-58a3-4ce1-a6ce-0d28074ffa4d/scratchpad/shots/`
(kallas `shots/` nedan; namnet slutar på `_1280x720.png` eller `_1560x720.png`). En kopia av rapporten och alla bilder
ligger i anteckningsmappen `side-session-notes/local_5cb7a8c0-…/provspel-0.30.14/` (scratchpad töms).

## Sammanfattning

1. Introts nya ordning (ed → smedja → övningsgård → makro → bibliotek → natten → nedstigningen) hänger ihop; Gorms
   "hundra silver" och Heddas "prova det hos Stig" sitter rätt. En kvarleva: Gorm säger "Makrona kommer när du har
   hållit ett riktigt svärd" fast svärdet redan är smitt.
2. Allvarligast: GÅ HEM finns även på första nedstigningen. Går man hem före första striden spelas hemkomsten ändå
   ("Längst ned satt en Benfurste", Imma "smet efter") och Imma rekryteras fast hon aldrig kom.
3. "Det här avgjorde striden" ritas utan bakgrund rakt ovanpå sällskapets ramar när man är tre eller fyra – oläsligt.
4. Smedjan i introt förväljer förmågan "Ingen". Hedda säger sedan att svärdet "slår till av sig självt", men det gör det
   bara med en förmåga, och introts kombination behöver Rättfärdigt slag.
5. En körning är 9–11 strider och ~75 steg, ungefär 25–60 minuter. Botarna bekräftar VD:s känsla: den som backar från
   vanliga grupper vinner **mindre** (kryptan 32 % → 15 %, första nedstigningen 86 % → 36 %), så att raka av grottan är
   det rätta draget.

## Fel, rangordnade

### Allvarligt

**A1. GÅ HEM under första nedstigningen ger fel berättelse och rekryterar Imma.**
`room_map_screen.gd` visar GÅ HEM alltid. `Run.leave_run()` → borgen → `base_screen.gd:322` ser att
`total_descents() > 0` (räknas upp redan när körningen startar, `run.gd:401`) och skickar `came_home`. Steget
`descent` har `"recruit": "imma"`, så Imma rekryteras, och nästa steg spelar Gorms och Immas hemkomstsamtal
("Ben. Massor av ben … Längst ned satt en Benfurste", "Jag tänkte på det hela vägen ned") även om spelaren vände
i första rutan och Imma aldrig smet efter. Samma sak händer redan i dag vid en förlust i första striden, men GÅ HEM
gör det till ett tryck.
- Återskapa: `godot --path . -- --intro-step=descent --talked --map`, tryck GÅ HEM → GÅ HEM; i borgen spelas
  hemkomsten (`shots/25_ask_leave_*` visar frågan; själva hemkomsten är läst i koden, inte skärmdumpad).
- Förslag: dölj GÅ HEM tills `intro_done` (eller tills första bossen), eller låt `came_home` kräva att Imma har
  anslutit/bossen är besegrad, och ge en egen kort replik från Gorm för en avbruten nedstigning.

### Medel

**M1. "Det här avgjorde striden" täcker sällskapets ramar (3–4 hjältar).** Rubriken och raderna (TROFÉ/KALL/EGEN …)
ritas från y≈270 till vänster utan bakgrundsplatta, ovanpå Syster Alvas och Brokks ramar och livmätare; texten blir
oläslig, i båda upplösningarna. Med två hjältar (introt) slutar ramarna ovanför och det syns rent.
- Återskapa: `godot --path . -- --all-companions --xp=3000 --encounter=crypt_1 --demo --turns=300 --seed=3`
  (`shots/22e_victory_1280x720.png`, `shots/22e_victory_1560x720.png`).
- Förslag: dölj ramarna på resultatskärmen, eller lägg panelen på en mörk platta under ramarna / till höger.

**M2. Smedjan i introt förväljer "Ingen" förmåga.** Bara svärdet går att välja, men förmågeraden står på "Ingen".
En ny spelare som trycker SMID direkt får ett svärd som aldrig slår till av sig självt. Heddas nästa replik
("Ibland slår svärdet till av sig självt när du anfaller. Se efter när det händer") blir då osann, och Immas tips om
Rökpil + Rättfärdigt slag pekar på en förmåga som inte sitter i svärdet (paladinen har den ändå som egen förmåga, så
kombinationen fungerar, men svärdet gör inget).
- Återskapa: `godot --path . -- --intro-step=forge --talked --smith --no-help` (`shots/04b_smith_nohelp_*`).
- Förslag: förvälj Rättfärdigt slag i introt (eller lås förmågan som typen), och låt hjälprutan säga det.

**M3. Gorms svar i övningssteget förutsätter den gamla ordningen.** Under steget "Vinn en övningsstrid" är svärdet
smitt, men trycker man på Gorms kammare säger han "Makrona kommer när du har hållit ett riktigt svärd."
(`intro.json` "replies"."macros").
- Återskapa: `godot --path . -- --intro-step=practice --talked --keep --talk=macros`
  (`shots/07_practice_macros_reply_*`).
- Förslag: t.ex. "Makrona kommer när du har prövat svärdet hos Stig."

**M4. Gamla profiler mitt i introt kan hoppa över Gorms svärdssamtal.** `Profile` flyttar steg 1/2 i den gamla
ordningen till svärdssteget men behåller `intro_talked`. En profil som hade fått Stigs uppdrag (talked = true) står
på svärdssteget med samtalet "givet" och hör aldrig Gorm ge hundra silver (silvret kommer ändå). En profil som stod
på gamla smedjesteget (2) gör övningsstriden två gånger. Liten påverkan, men lätt att nollställa `intro_talked` vid
flytten. (Läst i `profile.gd:634`, inte provat.)

**M5. Kombinationsrutan gick inte att fånga i skärmdump.** `--combo` (ALLA AUTO) kom inte fram till Paladinens
Rättfärdiga slag inom 600 bildrutor i något försök, och `--write-movie` frös bilden (känd fallgrop). Texten är läst i
koden (`battle.gd:991`) och ser rimlig ut. Notera: om samma hjälte både förblindade och slog säger rutan "Någon
gjorde …" i stället för namnet (`c.applier != e.source`). Föreslår en flagga som startar striden med Paladinen
först, så att rutan går att granska.

### Kosmetiskt

- **K1. Trofénamn klipps under trofé-platsen** hos smeden: "Gravprästens r" (`shots/24_trophy_slot_*`). Trofékorten i
  "TROFÉ UR SAMLINGEN" klipps mitt i meningen i 1280 ("Bärarens direkta attacker har 30 % chans", "… får
  sällskapet en Barriär för"); i 1560 klipps Dimmans slöja. Ingen ellips visar att det fortsätter.
  Återskapa: `godot --path . -- --forge-demo --smith --smith-hero=brokk --smith-slot=trophy:0 --no-help`.
  (Med flaggan visas Brokks sköld men ingen hjälte är markerad i listan, eftersom Brokk inte finns i demoprofilen.)
- **K2. Ramens egenskapsrad går utanför ramen**: "Fingerfärdig · Skelettets fingerled" sticker ut ~15 px till höger om
  Immas ram i striden (`shots/22d_victory_1280x720.png`, `shots/22e_*`).
- **K3. Volymreglagen ser inte ut som reglage**: två fyllda guldstaplar med "100 %", inget handtag
  (`shots/26_settings_keep_*`, `shots/27_settings_battle_*`). En ny spelare vet inte att man drar.
- **K4. GÅ HEM-frågan**: den farliga knappen (GÅ HEM) står först och ser likadan ut som STANNA; texten blandar "ni"
  och "du". Förslag: STANNA först eller GÅ HEM i rött.
- **K5. "Du svor eden i går"** säger Gorm samma natt som eden (berättaren: "Efter en lång dag … går du och lägger dig.
  Du vaknar av rop"). "i går kväll"/"i dag" eller låt det stå om det är efter midnatt.
- **K6. Stig lovar "Sedan kommer du hit och provar den"** men nästa uppdrag är Biblioteket; övningsgården går att
  besöka men inget pekar dit. Antingen ett litet steg "prova raden hos Stig" eller stryk meningen.
- **K7. Samlauppdraget på första våningen** för en ensam paladin är "ta 3 bevakade föremål", medan Gorm säger "Se efter
  och vänd. Slåss bara om du måste" (`shots/12_imma_joins_*`). Inte fel, men tonen krockar.

### Ingen anmärkning
Eden (Gorm ger 100 silver, `shots/01–02`), svärdssteget (`03–05`), Stigs Imma-inpass (`06`), makrosteget (`08`),
Biblioteket med Imma (`09`), natten med arbetarna (`10`), porten (`11`), Imma som smiter efter (`12`), hemkomsten och
svärdet till nivå 3 med nivå och kostnad överst (`13–14`), Spara som order (chipet ryms: "SPARA SOM ORDER: Rättfärdigt
slag mot Förblindad fiende", `21`), Visa fyndet för Hedda (`23b`), GÅ HEM-frågan (`25`), inställningarna (`26–27`),
Övningsgårdens nya rubrik och val "Prova makron i en övningsstrid" (`28–29`), grottan (`30`). Ingen text under 15 px
syntes, inget klipptes i telefonbredd i introt.

## Intryck som ny spelare

- Introt flyter bättre nu: svärdet först och sedan dockorna ger en anledning att gå till Stig. Replikerna är korta och
  har humor (Hedda och städet, Alriks glasögon, Immas "läxor"); natten med arbetarna är introts bästa scen.
- Silvret går jämnt ut: 60 + 100 = 160 = svärdet, och man går ned i kryptan med 0 silver. Det är rent, men en ny
  spelare ser att smedjan kostar "allt man har" utan förklaring.
- Kombinationen förklaras två gånger (Imma på rumskartan, rutan i striden) – bra. Men den hänger på att Rättfärdigt
  slag faktiskt används; med MANUELL och nybörjarens makro ("anfall den svagaste") händer det inte av sig självt.
- Spara som order är en tydlig liten knapp; 9 sekunder kan vara kort om man läser makrologgen samtidigt.
- Resultatskärmens "Det här avgjorde striden" är precis rätt idé (fingeravtryck av bygget), men den syns inte när
  sällskapet är fullt (M1).

## Körningens längd (botarna, djup 1, 100 körningar per rad)

`BALANS=grotta GROTTA_FORLUST=1` (4 min 43 s):

| Realm | Sällskap | MACRO vinst · strider (klarade) · steg | TUNED | MACRO försiktig |
|---|---|---|---|---|
| Kryptan | 4 hjältar nivå 3 | 32 % · 9,4 (11,1) · 78 | 45 % · 9,1 (10,6) · 76 | 15 % · 5,0 (6,5) · 84 |
| Kryptan | Paladinen + Imma nivå 3 | 58 % · 7,9 (11,0) · 66 | 39 % · 7,3 (11,3) · 61 | 9 % · 2,9 (8,1) · 55 |
| Kryptan | Första nedstigningen | 86 % · 9,6 (10,3) · 77 | 75 % · 9,2 (10,6) · 75 | 36 % · 5,6 (7,4) · 96 |
| Kapellet | 4 hjältar nivå 3 | 36 % · 8,7 (11,1) · 74 | 45 % · 9,1 (11,0) · 76 | 7 % · 4,6 (9,4) · 80 |
| Kapellet | Paladinen + Imma nivå 3 | 70 % · 8,2 (10,2) · 67 | 56 % · 7,5 (10,8) · 63 | 46 % · 3,6 (6,2) · 64 |
| Kapellet | Första nedstigningen | 91 % · 9,2 (10,1) · 75 | 96 % · 9,9 (10,1) · 80 | 85 % · 5,7 (6,3) · 97 |

Var körningarna förloras: 4 hjältar mest vid bossen (f1_end 31–49) och elitgruppen på våning 2; Paladinen + Imma
nästan bara vid **elitgruppen på våning 1** (f0_elite 28–54 av 100).

`BALANS=forsta` (6 min 17 s), vinst för hela körningen (v1 = våning 1):

| Rad | Kryptan MACRO / TUNED | Kapellet MACRO / TUNED |
|---|---|---|
| Första nedstigningen 0.25 (ensam, Imma efter strid 1) | 86 / 75 % | 91 / 96 % |
| Första nedstigningen med trappan [0,7, 0,88, 0,83] | 83 / 66 % | 99 / 96 % |
| Andra nedstigningen, nivå 3, en fånge | 60 / 52 % | 56 / 47 % |
| Ny profil nivå 1, befriar fångar | 20 / 19 % | 27 / 25 % |
| Ny profil nivå 1, ingen befrias | 13 / 6 % | 46 / 33 % |
| Paladinen + Imma + Brokk, nivå 3 | 71 / 68 % | 64 / 71 % |

Våning 1 klaras nästan alltid (80–100 %); det är våning 2 och bossen som fäller körningarna. Första nedstigningen är
snäll (86 %), men steget till nästa är brant: utan trappan och på nivå 1 vinner startmakrona i kryptan 13–20 %. Den som
förlorar första gången och går ned igen på låg nivå kan alltså fastna – det är värt att se vilken nivå sällskapet
faktiskt har efter första nedstigningen (botarna säger inte det).

**Speltid.** En klarad körning är ~10–11 strider. Med 2–5 minuter per strid blir det 20–55 minuter strid, plus ~75 steg
på kartan (pjäsen går själv till besökta rutor; ~2–4 min), rumsögonblick, lägereld, troféval och segerskärmar
(~5 min). **Ungefär 30–60 minuter per körning**, 15–35 minuter för den som backar från vanliga grupper (5–6 strider).
På en telefon i korta pass betyder det 2–4 sittningar per körning; körningen sparas mellan rummen, så det fungerar.

**Varför man rakar av grottan.** Botarna som backar från vanliga grupper ("försiktig") vinner tydligt mindre i alla
rader utom kapellets första nedstigning, och de körningar som klaras har fler strider än snittet (11,1 mot 9,4).
Strider ger erfarenhet (`grow`), medan fiendernas nivå bara följer djup och våning (`HeroStats.enemy_level`), inte hur
mycket man har slagits. Att kliva på allt är alltså inte slentrian utan rätt strategi – spelet belönar det. Frågor
till VD (inte beslut): ska bossen gå att klara utan att tömma våningen, dvs. ska erfarenheten per strid vara högre och
striderna färre? Skulle
questen eller en "snabbhetsbonus" (silver/fynd för få steg) göra det värt att gå direkt? Siralim löser det delvis med
stora våningar där man inte hinner allt; vår 8×8 är liten nog att tömma.

Övrigt ur siffrorna: TUNED-makrona är **sämre** än startmakrona för Paladinen + Imma (kryptan 39 mot 58 %, kapellet
56 mot 70 %), nästan helt vid våning 1:s elitgrupp – värt en titt i botens TUNED-makro för små sällskap.

## Att känna till

- Några av mina skärmdumpskörningar utan påhittad profil (`--floor=0 --demo`, `--find-quest --keep`, `--map
  --ask-leave`, `--practice`, `--keep --settings`) använde Mac:ens **sparplats 2**; dess `progress.cfg` ändrades
  2026-10-23 08:38 (troligen erfarenhet från en förlorad demostrid). `run.cfg` och `macros.json` är orörda. Telefonen
  påverkas inte. Därefter körde jag allt med `--all-companions`/`--intro-step` (sparas inte).
- `--floor=0 --demo` med sparplats 2 (Paladinen + Imma, nivå 1) förlorar mot kryptans första grupp utan
  första-nedstigningens trappa; ingen bugg, men ingen bra flagga för segerskärmen. `--all-companions` ändrar inte
  sällskapet i `--floor`/`--camp` (sällskapet blir ändå Paladinen + Imma) – en dev-flaggsfråga.
- Worktreen behövde `godot --headless --path . --import` innan balansrapporten gick (klasscachen saknades).
