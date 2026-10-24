# Textspel – hela provspelsloggen (oktober 2026)

Det här är en provspelning av **De edsvurna** (rpg007, gren `textspel` från `test-0.30`) gjord av en AI-agent genom
textläget `tests/text_play.gd`: spelets riktiga logik, ett kommando i taget, utan grafik. Dagboken med intrycken ligger i
`textspel-dagbok.md`. Loggen är kortad för att gå att klistra in i en annan chatt (~60 000 tecken).

## Spelet på tio rader

1. Ett turordnings-RPG för mobil, "Siralim Ultimate i 3D": djupet ligger i hur egenskaper kombineras.
2. Spelaren är en paladin (här döpt till **Arn**) som leder tre följeslagare: dvärgen **Brokk** (tank), **Syster Alva** (helare) och **Jägaren Eira** (bågskytt).
3. Paladinen har ett **kall** (Domens kall: slår tillbaka när sällskapet träffas) med **perks** som köps för perk-poäng.
4. Hemma i borgen väljer man **Realm** (Kryptan, Det fördärvade kapellet …) och **djup**; djupare = starkare fiender och bättre fynd.
5. En nedstigning är två våningar i en **grotta** på 8×8 rutor med dimma; man går ruta för ruta och möter fiendegrupper.
6. Varje våning har en **quest** (besegra Nemesis, rensa elitgrupper eller samla bevakade föremål); den låser upp trappan eller bossen.
7. Sista våningen slutar med huvudbossen (Benfursten i kryptan) eller ett djups roterande **väktare** (Midnattsklockan, Kistornas råd, Abbedissans kör).
8. Striderna spelas med **makron** (rader som "om någon allierad har liv < 40 % → Helande ljus"); här körde alla på AUTO.
9. Besegrade monster lämnar **troféer** som ger bäraren monstrets egenskap; troféer byts bara vid **lägereldar**. **Artefakter** smids och höjs hos smeden.
10. **Charges** (förmågornas laddningar) räcker hela nedstigningen; lägerelden ger +3 per förmåga en gång.

## Så läser du loggen

- `> kommando` är det spelaren skrev; raderna under är skärmen. `go c4 c5` = tryck på rutorna i tur och ordning.
- Kartan: `@@` ni, `..` besökt, `##` kan nås, `~~` dimma, `xx` spärrad av en sedd grupp, `rr` rykte om questens mål,
  `G`/`E`/`N`/`B` grupp/elit/Nemesis/boss, `>` trappa, `T` skatt, `H` helgedom, `L` lägereld, `Q` quest-föremål,
  `O` Realmens föremål; `!` = en grupp vaktar, liten bokstav = använd, `*` = låst.
- Strider: vanliga strider är kortade till en rad med fiender och resultat; för elit, Nemesis, väktare och boss står
  nyckelraderna kvar (`!!` = varslade attacker och väktarmekanik, `‹…›` = fiendens egenskap, `«…»` = sällskapets).
  `avgjorde:` är segerskärmens "Det här avgjorde striden". `nv 22` = fiendens nivå.
- Text som upprepas ordagrant (kortens egenskaper, troféernas texter) visas fullt första gången, sedan bara namnet.
- Utelämnat: tomma steg (samlade på en rad), silver per strid, erfarenhet, de flesta fynd av bärnsten och borgens
  fullständiga skärm efter varje smedjeköp. Den fullständiga råloggen (370 000 tecken) finns hos agenten.

## Loggen

```text
> new 11
Ny profil skapad: Arn, Domens kall, fyra hjältar på nivå 10–12, kryptan djup 3 och kapellet djup 2 klarade.
BORGEN – Arn, silver 420, perk-poäng 4/7 (Domens kall)
Vald nedstigning: Kryptan, djup 2 (klarat: Kryptan 3, Det fördärvade kapellet 2)
Djupets slut: Midnattsklockan
  Paladinen (paladin) nivå 12, trofé Det andra hugget, svärd nivå 5 (nästa 180 silver)
  Brokk (brokk) nivå 11, trofé Väktarens hjälm, sköld nivå 4 (nästa 140 silver)
  Syster Alva (alva) nivå 11, trofé Gravprästens radband, stav nivå 4 (nästa 140 silver)
  Jägaren Eira (eira) nivå 10, trofé Den kapade bågsträngen, stövlar nivå 3 (nästa 110 silver)
Värdshuset: imma (Imma, nivå 9), solveig (Solveig, nivå 8), tove (Broder Tove, nivå 7)
Perks: vengeance_wrath Vrede (1 p) ×1; vengeance_zeal Iver (1 p) ×1; vengeance_execution Domslut (1 p); vengeance_divine_toll Klockan klämtar (2 p) ×1; vengeance_reckoning Räkenskap (2 p); vengeance_hand_of_light Ljusets hand (3 p)

> trophies
Troféer (samlingen):
  bone_finger – Det andra hugget [common] (bärs av Arn): Efter en kritisk direkt attack gör bäraren ett följdanfall för 40 % (en gång per tur).
  warden_helm – Väktarens hjälm [common] (bärs av Brokk): När bäraren Försvarar eller Provocerar helas den svagaste i sällskapet för 140 % av bärarens Defense.
  rosary – Gravprästens radband [common] (bärs av Syster Alva): Bärarens Heliga skada helar den svagaste i sällskapet för 25 % av skadan.
  bow_sinew – Den kapade bågsträngen [common] (bärs av Jägaren Eira): Bärarens attacker mot märkta mål är alltid kritiska.

> macro brokk
Makro för Brokk:
  1. Om denna hjälte är på sin tur 1 → Förmåga: Krigsrop
  2. Om denna hjälte har liv < 50 % → Förmåga: Stenmur
  3. Om denna hjälte har liv > 50 % → pröva nästa rad
  4. Om denna hjälte har inte Provocerar → Provocera
  5. Om denna hjälte har liv < 50 % → Försvara
  6. Om någon fiende har lägst liv (%) → Anfall på den som matchade
  Förmågor: stone_wall (Stenmur), war_cry (Krigsrop)

> perk vengeance_reckoning
Perken Räkenskap köpt.

> perk vengeance_execution
Perken Domslut köpt.

> smith eira
Smeden Hedda höjer Jägaren Eiras artefakt till nivå 4 (−110 silver).

> start
=== Nedstigning 1: Kryptan, djup 2 ===
(Djupets väktare: Midnattsklockan)
  Brokk: ”Dåligt hugget. En dvärg hade skämts för den där väggen.”
Kryptan djup 2 – våning 1 av 2. Quest: Rensa: besegra 1 elitgrupp (0/1)
     a  b  c  d  e  f  g  h
1   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~
2   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ##
3   ~~ ~~ ~~ ~~ ~~ ~~ ## @@
4   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ##
5   ~~ ~~ ~~ rr rr rr ~~ ~~
6   ~~ ~~ ~~ rr rr rr ~~ ~~
7   ~~ ~~ ~~ rr rr rr ~~ ~~
8   ~~ >* ~~ ~~ ~~ ~~ ~~ ~~
Sällskap: Arn nv 12, Charges 13/13, Det andra hugget · Brokk nv 11, Charges 10/10, Väktarens hjälm · Syster Alva nv 11, Charges 16/16, Gravprästens radband · Jägaren Eira nv 10, Charges 14/14, Den kapade bågsträngen

> go g3 g4   (tomma rutor)

> go g5
  Jägaren Eira: ”Släpspår fram till kistan. Någon annan fick bära den hit.”
Skatt: +11 silver

> go f5 e5 e6 e7   (tomma rutor)

> go d7
  Syster Alva: ”De ser välrustade ut. Drick lite vatten innan vi går närmare.”
[ELITGRUPP] (Kolossens vakt)
2 fiender: Benkolossen, Skelettkrigare
  · Benrustning (Benkolossen): Tar 30 % mindre skada från attacker. Besvärjelser och indirekt skada biter fullt.
  · Växande vrede (Benkolossen): I början av varje egen tur får Benkolossen +10 % Attack (högst 5 gånger). Efter tre gånger sveper den med Benstorm.
  · Benmur (Benkolossen): Tar 5 % mindre skada för varje annan ur Benfolket som lever.
Kan lämna: Kolossens tålamod, Det andra hugget
Varning: en elitfiende är starkare än vanligt och har en egen regelbrytande egenskap. Backa och byt makro, eller troféer vid en lägereld, om det behövs.

> fight
=== STRID: Kolossens vakt ===
Fiender: Benkolossen nv 9, Skelettkrigare nv 9
--- SEGER efter 18 turer ---
Kvar: Arn 387/387, Brokk 575/575, Syster Alva 280/280, Jägaren Eira 241/241
  avgjorde: [EGEN] Jägarinstinkt (Jägaren Eira): 74 skada · 4 gånger
  avgjorde: [TROFÉ] Väktarens hjälm (Brokk): 53 helning · 3 gånger
Questen är klar: +19 silver, och trappan är öppen!
LÄGRET (välj en trofé):
  1) Kolossens tålamod [elite] – Bäraren får +8 % Attack i början av varje egen tur (högst 5 gånger).
  2) Den slocknade glöden [common] – När någon i sällskapet helas får bäraren en Glöd (högst 5). Bärarens nästa förmåga förbrukar dem: +15 % skada per Glöd.

> take 1
Ni tar med er Kolossens tålamod.

> go c7   (tomma rutor)

> go c6
[HELGEDOM] Välj en gåva – eller låt Pandemonium avgöra.
  1) +2 Charges: Pilregn (Jägaren Eira) – 6 av 6 kvar blir 8
  2) Sällskapet börjar nästa strid med Styrka – gör 15 % mer skada hela nästa strid
  3) Pandemonium: en slumpad effekt, bra eller dålig – +1 Charge på allt, Välsignad sköld (tar 30 % mindre skada), −1 Charge eller en våningsregel

> choose 1
+2 Charges: Pilregn (Jägaren Eira)

> go b6 c8 d8 e8 f8   (tomma rutor)

> go f7
[LÄGERELD] Elden sprakar. Att vila ger +3 Charges på varje förmåga, en gång. Troféerna kan ni byta här när som helst (swap <hjälte> <trofé>).

> swap arn colossus_patience
Arn bär nu ingen trofé.
[Anm.: fel i textverktyget – trofén hette colossus_spine och verktyget tog av den gamla i stället för att säga nej. Rättat direkt efteråt.]

> trophies
Troféer (körningens):

> trophies
Troféer (körningens):

> swap arn colossus_spine
Arn bär nu Kolossens tålamod.

> go f6
[FIENDEGRUPP] (Prästens nisch)
2 fiender: Skelettkrigare, Gravpräst
Vaktar en skatt.
  · Benrustning (Skelettkrigare): Tar 30 % mindre skada från attacker. Besvärjelser och indirekt skada biter fullt.
  · Gravpakt (Gravpräst): Gör 40 % mer skada för varje fallen allierad.

> fight
Strid: Prästens nisch – Skelettkrigare nv 7, Gravpräst nv 7
--- SEGER efter 7 turer ---
Skattkammaren: +11 silver och trofén Den slocknade glöden!
LÄGRET (välj en trofé):
  1) Den slocknade glöden [common] – När någon i sällskapet helas får bäraren en Glöd (högst 5). Bärarens nästa förmåga förbrukar dem: +15 % skada per Glöd.

> skip

> go b8
Ni går till b8 (6 steg).
[TRAPPAN] Questen är klar. Trappan leder ned till våning 2.

> go f7
Ni går till f7 (5 steg).
[LÄGERELD] (vila +3 Charges en gång, eller byt troféer)

> choose 1
Lägerelden: +11 Charges. Här kan ni byta troféer.
  Syster Alva: ”Drick vatten. Alla. Ja, du också, Imma.”

> go b8
Ni går till b8 (5 steg).
[TRAPPAN] Questen är klar. Trappan leder ned till våning 2.

> choose 1
Spåren efter 4 grupper ni lät vara: +204 erfarenhet, +25 silver.
Ni går ned till våning 2.
Kryptan djup 2 – våning 2 av 2. Quest: Samla: ta 3 bevakade föremål (0/3)
     a  b  c  d  e  f  g  h
1   rr rr rr ~~ ~~ ~~ ~~ ~~
2   rr rr rr ~~ ~~ ~~ ~~ ~~
3   r# rr rr ~~ ~~ ~~ ~~ ~~
4   @@ ## ~~ ~~ rr rr rr ~~
5   ## ~~ ~~ ~~ rr rr rr ~~
6   ~~ ~~ ~~ ~~ rr rr rr rr
7   ~~ ~~ ~~ ~~ ~~ rr rr rr
8   ~~ ~~ ~~ ~~ B* rr rr rr
Sällskap: Arn nv 12, Charges 11/13, Kolossens tålamod · Brokk nv 11, Charges 10/10, Väktarens hjälm · Syster Alva nv 11, Charges 13/16, Gravprästens radband · Jägaren Eira nv 11, Charges 16/14, Den kapade bågsträngen

> go a3 b3 b2 c2 c1 b1   (tomma rutor)

> go a1
[FIENDEGRUPP] (Glödande schakt)
2 fiender: Glödskelett, Benspringare
Vaktar ett av questens föremål.
  · Glödhetta (Glödskelett): Glödskelettets direkta träffar sätter Brinner på målet (30 % av dess Intelligence per tur i 2 turer).
  · Flockbett (Benspringare): Första anfallet i striden gör 25 % mer skada för varje annan ur Benfolket.

> fight
Strid: Glödande schakt – Glödskelett nv 9, Benspringare nv 9
--- SEGER efter 6 turer ---
Föremålet är ert. Samla: ta 3 bevakade föremål (1/3)
LÄGRET (välj en trofé):
  1) Springarens steg [common] – Bäraren börjar striden Smidig i 2 turer.

> skip

> go c3 d3 e3   (tomma rutor)

> go e4
[FIENDEGRUPP] (Väktarens port)
2 fiender: Gravväktare, Skelettbågskytt
Vaktar en skatt.
  · Taggig utmaning (Gravväktare): Medan Gravväktaren provocerar tar den som anfaller den 40 % av skadan tillbaka (indirekt). Besvärjelser slipper.
  · Jägarblick (Skelettbågskytt): Gör 50 % mer skada mot mål under 50 % liv.

> fight
Strid: Väktarens port – Gravväktare nv 9, Skelettbågskytt nv 9
--- SEGER efter 7 turer ---
  Brokk: ”Hm. Gångjärnen är bättre smidda än låset. Jag tar gärna båda.”
Skattkammaren: +15 silver
LÄGRET (välj en trofé):
  (ingen trofé den här gången – skip)

> skip

> go f4
[FIENDEGRUPP] (Likgropen)
3 fiender: Likätare, Skelettkrigare, Skelettbågskytt
Vaktar ett av questens föremål.
  · Gravhunger (Likätare): Varje måltid ger Likätaren +20 % Attack för resten av striden (högst 3 gånger). Det den äter kan aldrig väckas.
  · Benrustning (Skelettkrigare)
  · Jägarblick (Skelettbågskytt)

> go f5
Det går inte: en grupp står i vägen: anfall eller backa.
[FIENDEGRUPP] (Likgropen)
3 fiender: Likätare, Skelettkrigare, Skelettbågskytt
Vaktar ett av questens föremål.
  · Gravhunger (Likätare)
  · Benrustning (Skelettkrigare)
  · Jägarblick (Skelettbågskytt)

> fight
Strid: Likgropen – Gravgnagaren nv 9, Benkapten nv 9, Skelettbågskytt nv 9
!! Gravgnagaren är en elitfiende
!! Benkapten är en elitfiende
--- SEGER efter 14 turer ---
Föremålet är ert. Samla: ta 3 bevakade föremål (2/3)
LÄGRET (välj en trofé):
  1) Den brutna gravspaden [common] – Fiender som bäraren fäller kan inte väckas. Bäraren helas 10 % av sitt max liv när hen fäller en fiende.

> take 1
Ni tar med er Den brutna gravspaden.

> go g4 g5 g6   (tomma rutor)

> go g7
[FIENDEGRUPP] (Benvakten)
3 fiender: Skelettkrigare ×2, Gravpräst
Vaktar ett av questens föremål.
  · Benrustning (Skelettkrigare)
  · Gravpakt (Gravpräst)

> fight
Strid: Benvakten – Skelettkrigare 1 nv 10, Skelettkrigare 2 nv 10, Gravpräst nv 10
--- SEGER efter 9 turer ---
  Brokk når nivå 12!
  Syster Alva når nivå 12!
Föremålet är ert. Samla: ta 3 bevakade föremål (3/3)
Questen är klar: +38 silver!
LÄGRET (välj en trofé):
  (ingen trofé den här gången – skip)

> skip

> go f7   (tomma rutor)

> go e7
Skatt: +15 silver

> go e8
  Brokk: ”Bakom den här skölden står generationer av dvärghantverk. Och jag.”
[VÄKTARE] (Midnattsklockan)
Midnattsklockan: Klockaren vaktar djupet i bossens ställe.
Tre slag till midnatt: klockan väcker Benfolket, och det tredje slaget bryts bara om hela Benfolket har fallit.
4 fiender: Klockaren, Skelettkrigare, Benspringare, Gravpräst
Väktarens trofé: Midnattsklockans kläpp (1/2 segrar)
  · Resistent (Klockaren): Svagare effekt av Tystad, Hånad, Sover, Snärjd, Frusen, Blöder och Förstenad. Andra debuffar verkar fullt.
  · Klockslaget (Klockaren): Var tredje egen tur flyttas alla ur Benfolket överst på tidslinjen.
  · Benrustning (Skelettkrigare)
  · Flockbett (Benspringare)
  · Gravpakt (Gravpräst)
Kan lämna: Klockrepet, Det andra hugget, Springarens steg, Gravprästens radband
Motdrag – Klockaren: ni får bara väcka döda en gång per strid.

> fight
=== STRID: Midnattsklockan ===
Fiender: Klockaren nv 10, Skelettkrigare nv 10, Benspringare nv 10, Gravpräst nv 10
!! Klockaren laddar Klockan slår – slår om 1 tur
!! Klockaren släpper Klockan slår!
T8 Klockaren: Klockan slår → Klockaren
!! Klockaren laddar Klockan slår – slår om 1 tur
Brokk +155
--- SEGER efter 33 turer ---
Kvar: Arn 387/387, Brokk 621/621, Syster Alva 301/301, Jägaren Eira 260/260
  avgjorde: [KALL] Domens kall (Arn): 185 skada · 8 gånger
  avgjorde: [ARTEFAKT] Stav: Helande ljus (Syster Alva): 171 helning · 2 gånger
  Arn når nivå 13!
  Jägaren Eira når nivå 12!
LÄGRET (välj en trofé):
  1) Midnattsklockans kläpp [boss] – Var tredje gång bäraren agerar ljuder kläppen: alla fiender som laddar en varslad attack avbryts och vacklar. Men bäraren tar 15 % mer skada.
  2) Klockrepet [boss] – När fienderna flyttas överst på tidslinjen följer bäraren med (en gång per tur), men bäraren börjar striden längst ned.

> take 1
Ni tar med er Midnattsklockans kläpp.
=== Djupet är klarat! Ni går hem till borgen. ===
Kartan: { "realm": "crypt", "from": 1, "to": 0, "why": "quest" }
Kartan: { "realm": "chapel", "from": 1, "to": 2, "why": "neglect" }
I världen: cult_feast
BORGEN – Arn, silver 553, perk-poäng 7/7 (Domens kall)
Vald nedstigning: Kryptan, djup 2 (klarat: Det fördärvade kapellet 2, Kryptan 3)
Djupets slut: Midnattsklockan
  Arn (paladin) nivå 13, trofé Kolossens tålamod, svärd nivå 5 (nästa 180 silver)
  Brokk (brokk) nivå 12, trofé Väktarens hjälm, sköld nivå 4 (nästa 140 silver)
  Syster Alva (alva) nivå 12, trofé Gravprästens radband, stav nivå 4 (nästa 140 silver)
  Jägaren Eira (eira) nivå 12, trofé Den kapade bågsträngen, stövlar nivå 4 (nästa 140 silver)

> macro alva
Makro för Syster Alva:
  1. Om någon allierad har liv < 40 % → Förmåga: Helande ljus på den som matchade
  2. Om någon allierad har inte Läkning → pröva nästa rad
  3. Om någon allierad har liv < 80 % → Förmåga: Läkande hand på den som matchade
  4. Om någon fiende har lägst liv (%) → Förmåga: Ljusets dom på den som matchade
  5. Om någon fiende har lägst liv (%) → Anfall på den som matchade
  Förmågor: healing_light (Helande ljus), renew (Läkande hand), judgement (Ljusets dom)

> macro eira
Makro för Jägaren Eira:
  1. Om fiende 3 lever → Förmåga: Pilregn
  2. Om någon fiende har egenskapen Skyddande bön → Anfall på den som matchade
  3. Om någon fiende har egenskapen Gravpakt → Anfall på den som matchade
  4. Om någon fiende har Märkt → Anfall på den som matchade
  5. Om någon fiende har lägst liv (%) → Förmåga: Märk byte på den som matchade
  6. Om någon fiende kan skadas → Anfall på den som matchade
  Förmågor: hunters_mark (Märk byte), arrow_rain (Pilregn)

> macro arn
Makro för Arn:
  1. Om någon allierad har liv < 30 % → Förmåga: Helig sköld på den som matchade
  2. Om någon fiende har egenskapen Gravpakt → Förmåga: Rättfärdigt slag på den som matchade
  3. Om någon fiende har lägst liv (%) → Förmåga: Rättfärdigt slag på den som matchade
  4. Om någon fiende kan skadas → Anfall på den som matchade
  Förmågor: holy_smite (Rättfärdigt slag), holy_shield (Helig sköld)

> smith arn
Smeden Hedda höjer Arns artefakt till nivå 6 (−180 silver). Troféplats

> smith alva
Smeden Hedda höjer Syster Alvas artefakt till nivå 5 (−140 silver). Stat-plats 2

> depth 3
Djup 3 valt.

> start
=== Nedstigning 2: Kryptan, djup 3 ===
(Djupets väktare: Kistornas råd)
  Syster Alva: ”Fukten går genom manteln. Kom hit, jag fäster den tätare vid halsen.”
Kryptan djup 3 – våning 1 av 2. Quest: Jakt: besegra Nemesis (0/1)
     a  b  c  d  e  f  g  h
1   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~
2   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~
3   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~
4   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ##
5   ~~ ~~ ~~ ~~ ~~ ~~ ## @@
6   rr rr rr ~~ ~~ ~~ ~~ ##
7   rr rr rr ~~ ~~ ~~ ~~ ~~
8   >* rr rr ~~ ~~ ~~ ~~ ~~
Sällskap: Arn nv 13, Charges 13/13, Kolossens tålamod · Brokk nv 12, Charges 10/10, Väktarens hjälm · Syster Alva nv 12, Charges 16/16, Gravprästens radband · Jägaren Eira nv 12, Charges 14/14, Den kapade bågsträngen

> go g5 f5 e5 d5   (tomma rutor)

> go d6
Skatt: +14 silver

> go c6
[FIENDEGRUPP] (Benkryptans gång)
2 fiender: Skelettkrigare, Skelettbågskytt
Vaktar en skatt.
  · Benrustning (Skelettkrigare)
  · Jägarblick (Skelettbågskytt)

> fight
Strid: Benkryptans gång – Skelettkrigare nv 12, Skelettbågskytt nv 12
--- SEGER efter 7 turer ---
  Jägaren Eira: ”Damm på locket. Inga fingeravtryck. Det är åtminstone en början.”
Skattkammaren: +14 silver
LÄGRET (välj en trofé):
  1) Det andra hugget [common] – Efter en kritisk direkt attack gör bäraren ett följdanfall för 40 % (en gång per tur).
  2) Den slocknade glöden

> take 1
Ni tar med er Det andra hugget.

> go c7
[LÄGERELD] (vila +3 Charges en gång, eller byt troféer)

> choose 2

> go b7 b6 a7 b8 c8   (tomma rutor)

> go a6
Ni går till a6 (4 steg).
[NEMESIS] (Kolossens vakt)
2 fiender: Benkolossen, Skelettkrigare
  · Benrustning (Benkolossen)
  · Växande vrede (Benkolossen)
  · Benmur (Benkolossen)
Kan lämna: Kolossens tålamod, Det andra hugget

> fight
=== STRID: Kolossens vakt ===
Fiender: Nemesis: Benkolossen nv 14, Skelettkrigare nv 14
T26 Nemesis: Benkolossen: Benstorm → alla | Arn −17 | Brokk −27 | «Domens kall» | Nemesis: Benkolossen −24 | Syster Alva −26 | …
T31 Nemesis: Benkolossen: Benhugg → Brokk | Brokk −169 | «Domens kall» | Nemesis: Benkolossen −42 KRIT | Jägaren Eira står över…
--- SEGER efter 32 turer ---
Kvar: Arn 397/414, Brokk 395/621, Syster Alva 275/301, Jägaren Eira 251/280
  avgjorde: [TROFÉ] Väktarens hjälm (Brokk): 136 helning · 5 gånger
  avgjorde: [ARTEFAKT] Stav: Helande ljus (Syster Alva): 140 helning · 3 gånger
  Brokk når nivå 13!
  Syster Alva når nivå 13!
Questen är klar: +23 silver, och trappan är öppen!
  Syster Alva: ”Uppdraget är klart. Nu räknar jag huvuden, sedan får ni gå ner.”
Lägret: 1) Den slocknade glöden

> skip

> go c7
Ni går till c7 (3 steg).
[LÄGERELD] (vila +3 Charges en gång, eller byt troféer)

> choose 1
Lägerelden: +11 Charges. Här kan ni byta troféer.

> go a8
Ni går till a8 (3 steg).
[TRAPPAN] Questen är klar. Trappan leder ned till våning 2.

> choose 1
Spåren efter 4 grupper ni lät vara: +459 erfarenhet, +34 silver.
Ni går ned till våning 2.
  Brokk: ”Håll er bakom skölden. Dimman får väl också lära sig det.”
Kryptan djup 3 – våning 2 av 2. Quest: Samla: ta 3 bevakade föremål (0/3)
     a  b  c  d  e  f  g  h
1   ~~ ~~ ~~ ~~ rr rr rr ~~
2   B* ~~ ~~ ~~ rr rr rr ~~
3   ~~ ~~ ~~ ~~ rr rr rr ~~
4   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~
5   ~~ rr rr rr rr rr rr ##
6   ~~ rr rr rr rr rr r# @@
7   ~~ rr rr rr rr rr rr ##
8   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~
Sällskap: Arn nv 14, Charges 8/13, Kolossens tålamod · Brokk nv 13, Charges 10/10, Väktarens hjälm · Syster Alva nv 13, Charges 11/16, Gravprästens radband · Jägaren Eira nv 13, Charges 13/14, Den kapade bågsträngen

> go g6 f6 e6 d6 c6 c7   (tomma rutor)

> go b7 b6 b5
[FIENDEGRUPP] (Gnagda ben)
3 fiender: Likätare, Benspringare ×2
  · Gravhunger (Likätare)
  · Flockbett (Benspringare)

> fight
Strid: Gnagda ben – Gravgnagaren nv 15, Benspringare 1 nv 15, Benspringare 2 nv 15
!! Gravgnagaren är en elitfiende
--- SEGER efter 21 turer ---
LÄGRET (välj en trofé):
  1) Den sprängda bojan [elite] – När en fiende faller får bäraren +8 % Attack för resten av striden (högst 3 gånger).
  2) Den brutna gravspaden [common] – Fiender som bäraren fäller kan inte väckas. Bäraren helas 10 % av sitt max liv när hen fäller en fiende.

> take 1
Ni tar med er Den sprängda bojan.

> go b6 b5 c5 d5
[FIENDEGRUPP] (Glödande schakt)
2 fiender: Glödskelett, Benspringare
Vaktar en skatt.
  · Glödhetta (Glödskelett)
  · Flockbett (Benspringare)

> fight
Strid: Glödande schakt – Glödskelett nv 14, Benspringare nv 14
--- SEGER efter 4 turer ---
Skattkammaren: +18 silver och trofén Den slocknade glöden!
LÄGRET (välj en trofé):
  1) Den slocknade glöden
  2) Springarens steg [common] – Bäraren börjar striden Smidig i 2 turer.

> skip

> go d5 e5 f5 g5
[FIENDEGRUPP] (Kistbärarnas gång)
2 fiender: Kistbärare, Benspringare
Vaktar ett av questens föremål.
  · Sista tjänsten (Kistbärare): När Kistbäraren faller får alla ur Benfolket en Barriär för 50 % av dess Defense per levande ur Benfolket.
  · Flockbett (Benspringare)

> fight
Strid: Kistbärarnas gång – Kistbärare nv 14, Benspringare nv 14
--- SEGER efter 10 turer ---
  Brokk når nivå 14!
  Syster Alva når nivå 14!
  Jägaren Eira når nivå 14!
Föremålet är ert. Samla: ta 3 bevakade föremål (1/3)
LÄGRET (välj en trofé):
  1) Kistspiken [common] – När en allierad faller får sällskapet en Barriär för 8 % av bärarens max liv.
  2) Springarens steg

> skip

> go e5 f5 g5   (tomma rutor)

> go g6 g7 f7 e7
[FIENDEGRUPP] (Springarnas flock)
3 fiender: Benspringare ×2, Skelettbågskytt
Vaktar ett av questens föremål.
  · Flockbett (Benspringare)
  · Jägarblick (Skelettbågskytt)

> fight
Strid: Springarnas flock – Benspringare nv 14, Benvarg nv 14, Skelettbågskytt nv 14
!! Benvarg är en elitfiende
‹Vargens språng›
--- SEGER efter 15 turer ---
Föremålet är ert. Samla: ta 3 bevakade föremål (2/3)
LÄGRET (välj en trofé):
  1) Vargens språng [elite] – Bäraren börjar striden överst på tidslinjen.
  2) Springarens steg

> skip

> go g5 g4 g3 f3 f2
Ni går till g5 (3 steg).
[LÄGERELD] (vila +3 Charges en gång, eller byt troféer)

> choose 2

> go f2 f1 e1
[VÄKTARENS TIMGLAS] Sanden rinner baklänges om den får lite kraft. Offra en Charge, så visar timglaset var närmaste elitgrupp står.
  1) OFFRA EN CHARGE
  2) LÅT DET VARA
  3) LÅT DET VARA

> choose 2

> go e2 e3
Skatt: +18 silver

> go e3
[GRAVREGISTER] Alla finns med. Några har flyttat utan att meddela. Den fuktskadade boken räcker till en uppslagning.
  1) VÄRDESAKER
  2) BESVÄRLIGA GRANNAR
  3) LÅT DET VARA

> choose 2
Registret pekar ut 2 grupper.

> go f2 f1 g1
Ni går till f2 (2 steg).
[FIENDEGRUPP] (Likgropen)
3 fiender: Likätare, Skelettkrigare, Skelettbågskytt
Vaktar ett av questens föremål.
  · Gravhunger (Likätare)
  · Benrustning (Skelettkrigare)
  · Jägarblick (Skelettbågskytt)

> fight
Strid: Likgropen – Likätare nv 14, Skelettkrigare nv 14, Skelettbågskytt nv 14
--- SEGER efter 14 turer ---
Föremålet är ert. Samla: ta 3 bevakade föremål (3/3)
Questen är klar: +45 silver!
Lägret: 1) Den brutna gravspaden

> skip

> go f3
Ni går till f3 (3 steg).
[LÄGERELD] (vila +3 Charges en gång, eller byt troféer)

> choose 1
Lägerelden: +17 Charges. Här kan ni byta troféer.
  Syster Alva: ”Välkommen till mottagningen. Bänken är en sten, men filten är varm.”

> go b5 b4 b3 b2
Ni går till b5 (8 steg).
[HELGEDOM] Välj en gåva – eller låt Pandemonium avgöra.
  1) +2 Charges: Pilregn (Jägaren Eira)
  2) Sällskapet börjar nästa strid med Styrka
  3) Pandemonium: en slumpad effekt, bra eller dålig

> choose 2
Sällskapet börjar nästa strid med Styrka (gör 15 % mer skada hela nästa strid)

> go b3 a3 a2
Skatt: +18 silver

> go a3 a2
  Jägaren Eira: ”Inga flyktspår härifrån. Jag hade gärna sett några.”
[VÄKTARE] (Kistornas råd)
Kistornas råd: Gravväckaren vaktar djupet i bossens ställe.
Kistornas råd: när en i rådet faller ärver de andra hens egenskap. Välj ordningen.
3 fiender: Gravväckaren, Kistbärare ×2
Väktarens trofé: Rådets sigill (1/2 segrar)
  · Kallelse (Gravväckaren): Väckta allierade får en Barriär för 100 % av Gravväckarens Intelligence.
  · Sista tjänsten (Kistbärare)
Kan lämna: Den släckta lyktan, Kistspiken

> macro arn add 2 any_enemy has_trait=calling ability:holy_smite that
La till rad 2: Om någon fiende har egenskapen Kallelse → Förmåga: Rättfärdigt slag på den som matchade

> macro eira add 2 any_enemy has_trait=calling attack that
La till rad 2: Om någon fiende har egenskapen Kallelse → Anfall på den som matchade

> macro alva add 4 any_enemy has_trait=calling ability:judgement that
La till rad 4: Om någon fiende har egenskapen Kallelse → Förmåga: Ljusets dom på den som matchade

> fight
=== STRID: Kistornas råd ===
Fiender: Gravväckaren nv 15, Kistbärare 1 nv 15, Kistbärare 2 nv 15
T5 Arn: (artefakt) Rättfärdigt slag → Kistbärare 1 | Kistbärare 1 −38 | ‹Likvakan› | Kistbärare 2 +14
!! Gravväckaren föll; Gravens kraft går vidare till Kistbärare 1, Kistbärare 2
«Kolossens tålamod»
T11 Kistbärare 1: Kistslag → Syster Alva | Syster Alva −79 | «Domens kall» | Kistbärare 1 −12 | ‹Likvakan› | Kistbärare 2 +14
T17 Arn: (artefakt) Rättfärdigt slag → Kistbärare 1 | Kistbärare 1 −51 | ‹Likvakan› | Kistbärare 2 +14
T22 Arn: Anfall → Kistbärare 1 | Kistbärare 1 −48 | ‹Likvakan› | Kistbärare 2 +14
!! Kistbärare 1 föll; Jägarinstinkt går vidare till Kistbärare 2
--- SEGER efter 28 turer ---
Kvar: Arn 441/441, Brokk 575/713, Syster Alva 307/343, Jägaren Eira 319/319
  avgjorde: [TROFÉ] Väktarens hjälm (Brokk): 172 helning · 4 gånger
  avgjorde: [EGEN] Jägarinstinkt (Jägaren Eira): 166 skada · 5 gånger
  Arn når nivå 15!
LÄGRET (välj en trofé):
  1) Rådets sigill [boss] – När en allierad faller ärver bäraren hens troféegenskap resten av striden. Men bäraren tar emot 20 % mindre helning.
  2) Den släckta lyktan [elite] – En gång per strid: när någon i sällskapet faller väcks hen med 30 % liv.
  3) Kistspiken [common] – När en allierad faller får sällskapet en Barriär för 8 % av bärarens max liv.

> take 1
Ni tar med er Rådets sigill.
=== Djupet är klarat! Ni går hem till borgen. ===
Kartan: fördärvet i Det fördärvade kapellet växer (2 → 3).
Medan ni var borta: Pilgrimerna slutar komma: Mor Elin har ont om förband, och helarna får en Charge mindre tills kapellet trycks tillbaka.
Medan ni var borta: Tors arbetare skickade en gul bärnsten från kryptan.
Kampanjkartan: Kulten samlas till högtid – fäll biskopen (en nedstigning kvar)
BORGEN – Arn, silver 549, perk-poäng 7/7 (Domens kall)
Vald nedstigning: Kryptan, djup 3 (klarat: Det fördärvade kapellet 2, Kryptan 3)
Djupets slut: Kistornas råd
  Arn (paladin) nivå 15, trofé Kolossens tålamod, svärd nivå 6 (nästa 230 silver)
  Brokk (brokk) nivå 14, trofé Väktarens hjälm, sköld nivå 4 (nästa 140 silver)
  Syster Alva (alva) nivå 14, trofé Gravprästens radband, stav nivå 5 (nästa 180 silver)
  Jägaren Eira (eira) nivå 14, trofé Den kapade bågsträngen, stövlar nivå 4 (nästa 140 silver)

> socket arn 1 amber_bronze
Bronsfärgad bärnsten sitter nu i Arns artefakt.

> socket arn 2 amber_orange
Orange bärnsten sitter nu i Arns artefakt.

> socket alva 1 amber_violet
Violett bärnsten sitter nu i Syster Alvas artefakt.

> socket alva 2 amber_blue
Blå bärnsten sitter nu i Syster Alvas artefakt.

> socket brokk 1 amber_grey
Järngrå bärnsten sitter nu i Brokks artefakt.

> socket eira 1 amber_yellow
Gul bärnsten sitter nu i Jägaren Eiras artefakt.

> arttrophy arn bone_finger
Det andra hugget sitter nu i Arns artefakt (troféplatsen).

> smith brokk
Smeden Hedda höjer Brokks artefakt till nivå 5 (−140 silver). Stat-plats 2

> smith eira
Smeden Hedda höjer Jägaren Eiras artefakt till nivå 5 (−140 silver). Stat-plats 2

> realm chapel
Realm: Det fördärvade kapellet.

> depth 2
Djup 2 valt.

> start
=== Nedstigning 3: Det fördärvade kapellet, djup 2 ===
(Djupets väktare: Abbedissans kör)
  Jägaren Eira: ”Det droppar framför oss. Till vänster är marken torrare.”
Det fördärvade kapellet djup 2 – våning 1 av 2. Quest: Jakt: besegra Nemesis (0/1)
     a  b  c  d  e  f  g  h
1   @@ ## ~~ ~~ ~~ ~~ ~~ ~~
2   ## ~~ ~~ ~~ ~~ rr rr rr
3   ~~ ~~ ~~ ~~ ~~ rr rr rr
4   ~~ ~~ ~~ ~~ ~~ rr rr rr
5   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~
6   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~
7   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~
8   ~~ ~~ ~~ ~~ ~~ ~~ >* ~~
Sällskap: Arn nv 15, Charges 13/13, Kolossens tålamod · Brokk nv 14, Charges 10/10, Väktarens hjälm · Syster Alva nv 14, Charges 15/16, Gravprästens radband · Jägaren Eira nv 14, Charges 14/14, Den kapade bågsträngen

> go b1 c1 d1 e1 e2 f2
[FIENDEGRUPP] (Gisslarnas valv)
2 fiender: Botgörare, Gast
  · Bödelns märke (Botgörare): Botgörarens direkta träffar gör målet Sårbart: +50 % skada i 2 turer.
  · Eterisk (Gast): Undviker 40 % av attacker. Besvärjelser och indirekt skada träffar alltid.

> fight
Strid: Gisslarnas valv – Botgörare nv 7, Gast nv 7
--- SEGER efter 3 turer ---
  Brokk når nivå 15!
  Syster Alva når nivå 15!
LÄGRET (välj en trofé):
  1) Bödelns huva [common] – Bärarens kritiska träffar gör målet Sårbart: +50 % skada i 2 turer.
  2) Den rivna slöjan [common] – Bäraren undviker 20 % av attacker, och blir Smidig (25 % extra undvikande i 3 turer) varje gång hen undviker.

> take 1
Ni tar med er Bödelns huva.

> go d1 e1 f1 f2 g2 g3
[FIENDEGRUPP] (Gastarnas bänkrad)
2 fiender: Gast, Kultist
  · Eterisk (Gast)
  · Skyddande bön (Kultist): I början av sin tur ger Kultisten den svagaste allierade en Barriär för 120 % av sin Intelligence.

> fight
Strid: Gastarnas bänkrad – Gast nv 7, Kultist nv 7
--- SEGER efter 2 turer ---
  Jägaren Eira når nivå 15!
LÄGRET (välj en trofé):
  1) Den rivna slöjan [common] – Bäraren undviker 20 % av attacker, och blir Smidig (25 % extra undvikande i 3 turer) varje gång hen undviker.
  2) Det brustna bönebandet [common] – I början av bärarens tur får den svagaste i sällskapet en Barriär för 60 % av bärarens Intelligence.

> skip

> go f1 f2 g2 g3
[FIENDEGRUPP] (Paktens vakt)
2 fiender: Blodsvuren, Kultist
  · Blodpakt (Blodsvuren): Blodsvuren gör 10 % mer skada för varje tiondel liv den saknar (högst +50 %).
  · Skyddande bön (Kultist)

> fight
Strid: Paktens vakt – Blodsvuren nv 7, Kultist nv 7
--- SEGER efter 3 turer ---
LÄGRET (välj en trofé):
  1) Blodsvurens kniv [common] – Bäraren gör 6 % mer skada för varje tiondel liv hen saknar (högst +30 %).
  2) Det brustna bönebandet
  3) Den fallnes klinga [common] – Medan bäraren försvarar sig slår hen tillbaka mot varje attack för 50 %.

> skip

> go f2 g2 g3   (tomma rutor)

> go h3 h4 g4 f4 f3
[LÄGERELD] (vila +3 Charges en gång, eller byt troféer)

> choose 2

> go h4 g4 f4 f3
  Syster Alva: ”Vänta. Jag knyter förbandsväskan framtill den här gången.”
[NEMESIS] (Lansens anstormning)
4 fiender: Den svarta lansen, Spegelvakten, Irrbloss ×2
  · Anstormning (Den svarta lansen): Första anfallet i striden gör 200 % mer skada; sedan försvarar sig Lansen varannan tur.
  · Bruten ed (Den svarta lansen): När en annan ur De fallna faller blir Lansen Bärsärk i 2 turer.
  · Spegelsköld (Spegelvakten): Den som skadar Spegelvakten med en besvärjelse tar 40 % av skadan tillbaka (indirekt), +10 % för varje annan ur De fallna.
  · Flimmer (Irrbloss): Börjar striden överst på tidslinjen. Första träffen förblindar målet i 1 tur.
Kan lämna: Lansspetsen, Spegelskölden, Det släckta irrblosset

> fight
=== STRID: Lansens anstormning ===
Fiender: Nemesis: Den svarta lansen nv 9, Spegelvakten nv 9, Irrbloss 1 nv 9, Irrbloss 2 nv 9
--- SEGER efter 24 turer ---
Kvar: Arn 493/493, Brokk 731/759, Syster Alva 329/364, Jägaren Eira 338/338
  avgjorde: [KALL] Domens kall (Arn): 135 skada · 5 gånger
  avgjorde: [TROFÉ] Väktarens hjälm (Brokk): 83 helning · 2 gånger
Questen är klar: +19 silver, och trappan är öppen!
LÄGRET (välj en trofé):
  1) Lansspetsen [elite] – Bärarens första Anfall i striden struntar i Defense.
  2) Det släckta irrblosset [common] – Bäraren undviker attacker så ofta det går (taket för undvikande, 75 %) tills hen har agerat första gången.

> take 1
Ni tar med er Lansspetsen.

> go g5 g6 g7 g8
[VÄKTARENS TIMGLAS] Sanden rinner baklänges om den får lite kraft. Offra en Charge, så visar timglaset var närmaste elitgrupp står. (Ett val går inte än: ni har inte sett någon grupp att barrikadera bort.)
  1) LÅT DET VARA

> go g6 g7 g8
Skatt: +11 silver

> go h3
Ni går till h3 (5 steg).
[LÄGERELD] (vila +3 Charges en gång, eller byt troféer)

> choose 1
Lägerelden: +14 Charges. Här kan ni byta troféer.

> go g8
Ni går till g8 (6 steg).
[TRAPPAN] Questen är klar. Trappan leder ned till våning 2.

> choose 1
Spåren efter 1 grupper ni lät vara: +51 erfarenhet, +8 silver.
Ni går ned till våning 2.
  Syster Alva: ”Känn efter om stövlarna skaver. Jag tänker inte låta dimman få skulden sedan.”
Det fördärvade kapellet djup 2 – våning 2 av 2. Quest: Samla: ta 3 bevakade föremål (0/3)
     a  b  c  d  e  f  g  h
1   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~
2   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~
3   ~~ ~~ ~~ rr rr rr B* ~~
4   rr rr rr rr rr rr ~~ ~~
5   rr rr rr rr rr rr rr rr
6   rr rr rr ~~ ~~ rr rr rr
7   ~~ ~~ ## ~~ ~~ rr rr rr
8   ~~ ## @@ ## ~~ ~~ ~~ ~~
Sällskap: Arn nv 15, Charges 10/13, Kolossens tålamod · Brokk nv 15, Charges 10/10, Väktarens hjälm · Syster Alva nv 15, Charges 13/16, Gravprästens radband · Jägaren Eira nv 15, Charges 14/14, Den kapade bågsträngen

> go c7 c6 c5 b5   (tomma rutor)

> go a5 a4 b4 c4 d4
[FIENDEGRUPP] (Spegelkoret)
2 fiender: Spegelvakten, Häxa
Vaktar ett av questens föremål.
  · Spegelsköld (Spegelvakten)
  · Häxans illvilja (Häxa): Gör 50 % mer skada mot tystade mål.

> fight
Strid: Spegelkoret – Silverspegeln nv 9, Häxmästarinna nv 9
!! Silverspegeln är en elitfiende
!! Häxmästarinna är en elitfiende
--- SEGER efter 6 turer ---
Föremålet är ert. Samla: ta 3 bevakade föremål (1/3)
LÄGRET (välj en trofé):
  1) Silverskärvan [elite] – Första besvärjelsen som skadar bäraren i striden studsar tillbaka: bäraren får livet tillbaka och kastaren tar lika mycket (indirekt).
  2) Häxmästarinnans brutna spira [elite] – Bärarens förmågor har 30 % chans att kastas en gång till, utan Charge.
  3) Spegelskölden [common] – Den som skadar bäraren med en besvärjelse tar 60 % tillbaka (indirekt).

> skip

> go c4 d4 e4   (tomma rutor)

> go e3 f3 f4 f5
[LÖS KYRKBÄNK] Gedigen ek. Fortfarande användbar till ordning och reda. Barrikadera bort en grupp ni har sett (den ger då ingenting), eller ta virket. (Ett val går inte: ni har inte sett någon grupp att barrikadera bort)
  1) TA VIRKET
  2) LÅT DET VARA

> choose 1
Gedigen ek: +15 silver.

> go f3 f4 f5
[FIENDEGRUPP] (Biskopens livvakt)
3 fiender: Fallen riddare, Häxa, Kultist
Vaktar ett av questens föremål.
  · Motstöt (Fallen riddare): Medan Den fallne riddaren försvarar sig slår den tillbaka mot varje attack för 60 %. Besvärjelser slipper.
  · Häxans illvilja (Häxa)
  · Skyddande bön (Kultist)

> fight
Strid: Biskopens livvakt – Fallen riddare nv 10, Häxa nv 10, Kultist nv 10
--- SEGER efter 11 turer ---
Föremålet är ert. Samla: ta 3 bevakade föremål (2/3)
LÄGRET (välj en trofé):
  1) Den fallnes klinga [common] – Medan bäraren försvarar sig slår hen tillbaka mot varje attack för 50 %.
  2) Den brutna trollstaven [common] – Bärarens direkta besvärjelser har 50 % chans att tysta målet i 1 tur (fiender kan då bara anfalla).
  3) Det brustna bönebandet [common] – I början av bärarens tur får den svagaste i sällskapet en Barriär för 60 % av bärarens Intelligence.

> take 1
Ni tar med er Den fallnes klinga.

> go f5 f6 g6 g5 h5
[FIENDEGRUPP] (Den skyddade diakonen)
3 fiender: Kultist, Fördärvad diakon, Gast
Vaktar ett av questens föremål.
  · Skyddande bön (Kultist)
  · Grumlad välsignelse (Fördärvad diakon): Diakonens helningar på Kultens folk ger Läkning i 2 turer.
  · Eterisk (Gast)

> fight
Strid: Den skyddade diakonen – Kultist nv 9, Fördärvad diakon nv 9, Gast nv 9
--- SEGER efter 5 turer ---
Föremålet är ert. Samla: ta 3 bevakade föremål (3/3)
Questen är klar: +38 silver!
LÄGRET (välj en trofé):
  1) Det brustna bönebandet [common] – I början av bärarens tur får den svagaste i sällskapet en Barriär för 60 % av bärarens Intelligence.
  2) Den rivna slöjan

> skip

> go f3 g3
Ni går till f3 (2 steg).
  Jägaren Eira: ”Spåren viker undan här. Vi håller ihop.”
[VÄKTARE] (Abbedissans kör)
Abbedissans kör: Den fördärvade abbedissan vaktar djupet i bossens ställe.
Systrarnas krona: bara den som bär kronan tar full skada. Kronan flyttar efter tre av bärarens turer.
4 fiender: Den fördärvade abbedissan, Fördärvad diakon ×2, Häxa
Väktarens trofé: Den vandrande kronan (1/2 segrar)
  · Resistent (Den fördärvade abbedissan): Svagare effekt av Tystad, Hånad, Sover, Snärjd, Frusen, Blöder och Förstenad. Andra debuffar verkar fullt.
  · Mässan (Den fördärvade abbedissan): Var tredje egen tur helas alla hennes allierade för 30 % av sitt liv och renas från debuffar.
  · Grumlad välsignelse (Fördärvad diakon)
  · Häxans illvilja (Häxa)
Kan lämna: Abbedissans nyckel, Diakonens stola, Den brutna trollstaven
Motdrag – Den fördärvade abbedissan: ni kan bara helas en gång per tur.

> macro arn add 2 any_enemy has_status=sisters_crown ability:holy_smite that
La till rad 2: Om någon fiende har Systrarnas krona → Förmåga: Rättfärdigt slag på den som matchade

> macro eira add 2 any_enemy has_status=sisters_crown attack that
La till rad 2: Om någon fiende har Systrarnas krona → Anfall på den som matchade

> macro alva add 4 any_enemy has_status=sisters_crown ability:judgement that
La till rad 4: Om någon fiende har Systrarnas krona → Förmåga: Ljusets dom på den som matchade

> fight
=== STRID: Abbedissans kör ===
Fiender: Den fördärvade abbedissan nv 10, Fördärvad diakon 1 nv 10, Fördärvad diakon 2 nv 10, Häxa nv 10
‹Systrarnas krona›
!! Systrarnas krona går från Den fördärvade abbedissan till Fördärvad diakon 1
«Kolossens tålamod»
!! Systrarnas krona går från Fördärvad diakon 1 till Fördärvad diakon 2
--- SEGER efter 20 turer ---
Kvar: Arn 465/493, Brokk 750/759, Syster Alva 364/364, Jägaren Eira 338/338
  avgjorde: [ARTEFAKT] Svärd: Rättfärdigt slag (Arn): 201 skada · 2 gånger
  avgjorde: [EGEN] Jägarinstinkt (Jägaren Eira): 155 skada · 3 gånger
  Arn når nivå 16!
LÄGRET (välj en trofé):
  1) Den vandrande kronan [boss] – Bäraren börjar striden med kronan: den som bär den tar 30 % mindre skada men gör 15 % mindre. Efter tre av bärarens turer, eller när hen faller, går kronan till den allierade med lägst liv.
  2) Abbedissans nyckel [boss] – När bäraren helar någon renas målet från alla debuffar, men bärarens helningar är 20 % svagare.
  3) Den brutna trollstaven [common] – Bärarens direkta besvärjelser har 50 % chans att tysta målet i 1 tur (fiender kan då bara anfalla).

> take 1
Ni tar med er Den vandrande kronan.
=== Djupet är klarat! Ni går hem till borgen. ===
Kartan: fördärvet i Det fördärvade kapellet viker (3 → 1).
Kartan: fördärvet i Kryptan växer (0 → 1).
Medan ni var borta: Kulten samlas till högtid: Högtiden bröts innan den började. Kapellet tystnade.
Medan ni var borta: Pilgrimerna kommer igen: Mor Elin har förband.
Medan ni var borta: En pilgrim sitter i värdshuset: han vet var nästa körnings första mål står, vilken Realm ni än väljer.
Medan ni var borta: Tors arbetare skickade en turkos bärnsten från kryptan.
BORGEN – Arn, silver 538, perk-poäng 7/7 (Domens kall)
Vald nedstigning: Det fördärvade kapellet, djup 2 (klarat: Det fördärvade kapellet 2, Kryptan 3)
Djupets slut: Abbedissans kör
  Arn (paladin) nivå 16, trofé Kolossens tålamod, svärd nivå 6 (nästa 230 silver)
  Brokk (brokk) nivå 15, trofé Väktarens hjälm, sköld nivå 5 (nästa 180 silver)
  Syster Alva (alva) nivå 15, trofé Gravprästens radband, stav nivå 5 (nästa 180 silver)
  Jägaren Eira (eira) nivå 15, trofé Den kapade bågsträngen, stövlar nivå 5 (nästa 180 silver)

> socket brokk 2 amber_teal
Turkos bärnsten sitter nu i Brokks artefakt.

> socket eira 2 amber_red
Röd bärnsten sitter nu i Jägaren Eiras artefakt.

> smith alva
Smeden Hedda höjer Syster Alvas artefakt till nivå 6 (−180 silver). Troféplats

> smith brokk
Smeden Hedda höjer Brokks artefakt till nivå 6 (−180 silver). Troféplats

> realm crypt
Realm: Kryptan.

> depth 4
Djup 4 valt.

> arttrophy brokk fallen_oath
Den fallnes klinga sitter nu i Brokks artefakt (troféplatsen).

> arttrophy alva prayer_beads
Det brustna bönebandet sitter nu i Syster Alvas artefakt (troféplatsen).

> start
=== Nedstigning 4: Kryptan, djup 4 ===
  Jägaren Eira: ”Färska spår. Dimman har inte sopat golvet.”
Kryptan djup 4 – våning 1 av 2. Quest: Samla: ta 3 bevakade föremål (0/3)
     a  b  c  d  e  f  g  h
1   ~~ ~~ ~~ ~~ ~~ ## @@ ##
2   ~~ ~~ ~~ ~~ ~~ ~~ ## ~~
3   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~
4   ~~ ~~ ~~ ~~ Q! ~~ ~~ ~~
5   ~~ Q! ~~ ~~ ~~ ~~ ~~ ~~
6   ~~ >* ~~ ~~ ~~ ~~ ~~ ~~
7   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~
8   ~~ ~~ ~~ ~~ Q! ~~ ~~ ~~
Sällskap: Arn nv 16, Charges 13/13, Kolossens tålamod · Brokk nv 15, Charges 10/10, Väktarens hjälm · Syster Alva nv 15, Charges 16/16, Gravprästens radband · Jägaren Eira nv 15, Charges 14/14, Den kapade bågsträngen

> go g2 g3 f3 f4 e4
[LÄGERELD] (vila +3 Charges en gång, eller byt troféer)

> choose 2

> go f3 f4 e4
  Jägaren Eira: ”Djupa avtryck. Tung rustning. Marken varnade oss först.”
[ELITGRUPP] (Kolossens vakt)
2 fiender: Benkolossen, Skelettkrigare
  · Benrustning (Benkolossen)
  · Växande vrede (Benkolossen)
  · Benmur (Benkolossen)
Kan lämna: Kolossens tålamod, Det andra hugget

> fight
=== STRID: Kolossens vakt ===
Fiender: Benkolossen nv 19, Benkapten nv 19
!! Benkapten är en elitfiende
T25 Benkolossen: Benstorm → alla | Arn −0 (barriär 20) | Brokk −0 (barriär 9) | Syster Alva −35 | «Domens kall» | Benkolossen −…
T29 Syster Alva: Ljusets dom → Benkolossen | Benkolossen −62 | «Gravprästens radband» | Brokk +16 | «Kolossens tålamod» | Arn s…
--- SEGER efter 33 turer ---
Kvar: Arn 522/522, Brokk 481/800, Syster Alva 329/364, Jägaren Eira 328/338
  avgjorde: [ARTEFAKT] Stav: Helande ljus (Syster Alva): 452 helning · 4 gånger
  avgjorde: [TROFÉ] Väktarens hjälm (Brokk): 208 helning · 4 gånger
  Brokk når nivå 16!
  Syster Alva når nivå 16!
  Jägaren Eira når nivå 16!
Fynd: 1 × Turkos bärnsten (+Health / +Defense), 1 × Violett bärnsten (+Intelligence / +Speed), Sårbarhetens kuriosa (Trick: 12 % chans at…
LÄGRET (välj en trofé):
  1) Kaparens första hugg [elite] – Bärarens första Anfall i striden gör 200 % mer skada.
  2) Det andra hugget [common] – Efter en kritisk direkt attack gör bäraren ett följdanfall för 40 % (en gång per tur).
  3) Den slocknade glöden [common] – När någon i sällskapet helas får bäraren en Glöd (högst 5). Bärarens nästa förmåga förbrukar dem: +15 % skada per Glöd.

> take 1
Ni tar med er Kaparens första hugg.

> go e4
[FIENDEGRUPP] (Prästens nisch)
2 fiender: Skelettkrigare, Gravpräst
Vaktar ett av questens föremål.
  · Benrustning (Skelettkrigare)
  · Gravpakt (Gravpräst)

> fight
Strid: Prästens nisch – Skelettkrigare nv 17, Gravpräst nv 17
--- SEGER efter 8 turer ---
Föremålet är ert. Samla: ta 3 bevakade föremål (1/3)
Lägret: 1) Det andra hugget; 2) Den slocknade glöden

> skip

> go d4 c4 c5 b5
[FIENDEGRUPP] (Askkoret)
3 fiender: Glödskelett, Skelettkrigare, Gravpräst
Vaktar ett av questens föremål.
  · Glödhetta (Glödskelett)
  · Benrustning (Skelettkrigare)
  · Gravpakt (Gravpräst)

> fight
Strid: Askkoret – Glödskelett nv 19, Skelettkrigare nv 19, Gravabbot nv 19
!! Gravabbot är en elitfiende
--- SEGER efter 13 turer ---
Föremålet är ert. Samla: ta 3 bevakade föremål (2/3)
LÄGRET (välj en trofé):
  1) Den återtända ljusstaken [elite] – I början av bärarens tur helas hela sällskapet för 8 % av bärarens max liv.
  2) Den slocknade glöden

> take 1
Ni tar med er Den återtända ljusstaken.

> go c6 c7 d7 d8 e8
Ni går till c6 (2 steg).
[FIENDEGRUPP] (Kistbärarnas gång)
2 fiender: Kistbärare, Benspringare
Vaktar ett av questens föremål.
  · Sista tjänsten (Kistbärare)
  · Flockbett (Benspringare)

> fight
Strid: Kistbärarnas gång – Kistbärare nv 19, Benspringare nv 19
--- SEGER efter 12 turer ---
  Arn når nivå 17!
Föremålet är ert. Samla: ta 3 bevakade föremål (3/3)
Questen är klar: +26 silver, och trappan är öppen!
  Jägaren Eira: ”Drag från trappan. Fuktigare där nere. Behåll manteln på.”
Lägret: 1) Kistspiken; 2) Springarens steg; 3) Den slocknade glöden

> skip

> go g3
Ni går till g3 (11 steg).
[LÄGERELD] (vila +3 Charges en gång, eller byt troféer)

> choose 1
Lägerelden: +14 Charges. Här kan ni byta troféer.

> trophies
Troféer (körningens):
  colossus_spine – Kolossens tålamod [elite] (bärs av Arn): Bäraren får +8 % Attack i början av varje egen tur (högst 5 gånger).

> swap arn bearer_of_light
Arn bär nu Den återtända ljusstaken.

> go b6
Ni går till b6 (8 steg).
[TRAPPAN] Questen är klar. Trappan leder ned till våning 2.

> choose 1
Spåren efter 1 grupper ni lät vara: +204 erfarenhet, +8 silver.
Ni går ned till våning 2.
Kryptan djup 4 – våning 2 av 2. Quest: Rensa: besegra 2 elitgrupper (0/2)
     a  b  c  d  e  f  g  h
1   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~
2   B* ~~ ~~ ~~ ~~ ~~ ~~ ~~
3   rr rr rr ~~ ~~ ~~ ~~ ~~
4   rr rr rr ~~ ~~ ~~ ~~ ##
5   rr rr rr ~~ ~~ ~~ ## @@
6   ~~ ~~ ~~ ~~ ~~ rr rr r#
7   ~~ ~~ ~~ ~~ ~~ rr rr rr
8   ~~ ~~ ~~ ~~ ~~ rr rr rr
Sällskap: Arn nv 17, Charges 8/13, Den återtända ljusstaken · Brokk nv 16, Charges 9/10, Väktarens hjälm · Syster Alva nv 16, Charges 11/16, Gravprästens radband · Jägaren Eira nv 16, Charges 11/14, Den kapade bågsträngen

> go h6 h7 g7
[FIENDEGRUPP] (Glödande schakt)
2 fiender: Glödskelett, Benspringare
  · Glödhetta (Glödskelett)
  · Flockbett (Benspringare)

> back
Ni backar till h7. Gruppen står kvar och spärrar rutorna intill sig.
  Syster Alva: ”Kom bakom mig tills yrseln släpper. Håll i min axel.”

> go h8
[HELGEDOM] Välj en gåva – eller låt Pandemonium avgöra.
  1) +2 Charges: Rättfärdigt slag (Arn) – 3 av 8 kvar blir 5
  2) Sällskapet börjar nästa strid med Värnad – tar 20 % mindre skada hela nästa strid
  3) Pandemonium: en slumpad effekt, bra eller dålig

> choose 1
+2 Charges: Rättfärdigt slag (Arn)

> go h7 g7
[FIENDEGRUPP] (Glödande schakt)
2 fiender: Glödskelett, Benspringare
  · Glödhetta (Glödskelett)
  · Flockbett (Benspringare)

> fight
Strid: Glödande schakt – Glödskelett nv 19, Benspringare nv 19
--- SEGER efter 7 turer ---
  Brokk når nivå 17!
  Syster Alva når nivå 17!
  Jägaren Eira når nivå 17!
Lägret: 1) Den slocknade glöden; 2) Springarens steg

> skip

> go f7 f6 g6   (tomma rutor)

> go g8 f8
Ni går till g8 (2 steg).
  Jägaren Eira: ”De har ställt sig utanför pilhåll. Någon av dem tänker.”
[ELITGRUPP] (Klockstapeln)
3 fiender: Klockaren, Skelettkrigare, Benspringare
  · Resistent (Klockaren)
  · Klockslaget (Klockaren)
  · Benrustning (Skelettkrigare)
  · Flockbett (Benspringare)
Kan lämna: Klockrepet, Det andra hugget, Springarens steg
Motdrag – Klockaren: ni får bara väcka döda en gång per strid.

> fight
=== STRID: Klockstapeln ===
Fiender: Klockaren nv 20, Skelettkrigare nv 20, Benspringare nv 20
--- SEGER efter 37 turer ---
Kvar: Arn 550/550, Brokk 897/897, Syster Alva 406/406, Jägaren Eira 377/377
  avgjorde: [TROFÉ] Den återtända ljusstaken (Arn): 443 helning · 6 gånger
  avgjorde: [TROFÉ] Väktarens hjälm (Brokk): 266 helning · 5 gånger
LÄGRET (välj en trofé):
  1) Klockrepet [boss] – När fienderna flyttas överst på tidslinjen följer bäraren med (en gång per tur), men bäraren börjar striden längst ned.
  2) Det andra hugget

> skip

> go e8 d8 d7 d6
[FIENDEGRUPP] (Väktarens port)
2 fiender: Gravväktare, Skelettbågskytt
  · Taggig utmaning (Gravväktare)
  · Jägarblick (Skelettbågskytt)

> back
Ni backar till f8. Gruppen står kvar och spärrar rutorna intill sig.

> go f6 e6 d6 c6
Ni går till f6 (2 steg).
[FIENDEGRUPP] (Glödande schakt)
2 fiender: Glödskelett, Benspringare
Vaktar en fånge.
  · Glödhetta (Glödskelett)
  · Flockbett (Benspringare)

> fight
--- SEGER efter 9 turer ---
  Syster Alva: ”Välkommen. Var har du ont?”
LÄGRET (välj en trofé):
  1) Den slocknade glöden
  2) Springarens steg
  3) Det andra hugget [common] – Efter en kritisk direkt attack gör bäraren ett följdanfall för 40 % (en gång per tur).

> skip
[EN FÅNGE BEFRIAS] Sefir av Sanden befrias! Svärdsdansare. Sällskapet är fullt – väntar i Värdshuset.
  1) VÄLKOMMEN!

> choose 1

> go c6 c5 b5   (tomma rutor)

> go b4 c4 c3 b3
  1) VÄRDESAKER
  2) BESVÄRLIGA GRANNAR
  3) LÅT DET VARA

> choose 2
Registret pekar ut 2 grupper.

> go c4 c3   (tomma rutor)

> go c2 b2
[LÄGERELD] (vila +3 Charges en gång, eller byt troféer)

> choose 2

> go c3 b3
[ELITGRUPP] (Likfärden)
3 fiender: Kistbärare, Benspringare, Skelettbågskytt
  · Sista tjänsten (Kistbärare)
  · Flockbett (Benspringare)
  · Jägarblick (Skelettbågskytt)
Kan lämna: Kistspiken, Springarens steg, Den kapade bågsträngen
Motdrag – Likbärare: när den faller gör den 3 anfall mot slumpade hjältar.

> fight
=== STRID: Likfärden ===
Fiender: Likbärare nv 20, Benspringare nv 20, Skelettbågskytt nv 20
!! Likbärare är en elitfiende
--- SEGER efter 27 turer ---
Kvar: Arn 550/550, Brokk 897/897, Syster Alva 406/406, Jägaren Eira 349/377
  avgjorde: [TROFÉ] Den återtända ljusstaken (Arn): 247 helning · 3 gånger
  avgjorde: [TROFÉ] Väktarens hjälm (Brokk): 174 helning · 3 gånger
  Arn når nivå 18!
Fynd: 1 × Bronsfärgad bärnsten (+Attack / +Defense), 1 × Blå bärnsten (+Intelligence), Brynsten (Trick: Anfall gör 12 % mer skada.)
Questen är klar: +53 silver och en perk-poäng!
LÄGRET (välj en trofé):
  1) Sista vaktens sköld [elite] – Första gången en allierad faller blir bäraren Provocerande i 2 turer.
  2) Kistspiken [common] – När en allierad faller får sällskapet en Barriär för 8 % av bärarens max liv.
  3) Springarens steg [common] – Bäraren börjar striden Smidig i 2 turer.
  4) Det andra hugget [common] – Efter en kritisk direkt attack gör bäraren ett följdanfall för 40 % (en gång per tur).

> take 1
Ni tar med er Sista vaktens sköld.

> go c3 c2
[LÄGERELD] (vila +3 Charges en gång, eller byt troféer)

> choose 1
Lägerelden: +20 Charges. Här kan ni byta troféer.

> go b2 a2
Skatt: +21 silver

> go a2
  Syster Alva: ”Låt mig fästa manteln. Du ska inte snubbla när det gäller.”
[BOSS] (Benfurstens sal)
3 fiender: Benfursten, Skelettkrigare, Gravpräst
  · Resistent (Benfursten): Svagare effekt av Tystad, Hånad, Sover, Snärjd, Frusen, Blöder och Förstenad. Andra debuffar verkar fullt.
  · Odödlig vrede (Benfursten): Första gången Benfursten faller under 50 % liv vredgas han: +50 % skada resten av striden, och han sveper sällskapet med Benstorm direkt.
  · Benrustning (Skelettkrigare)
  · Gravpakt (Gravpräst)
Kan lämna: Det andra hugget, Gravprästens radband

> fight
=== STRID: Benfurstens sal ===
Fiender: Benfursten nv 20, Skelettkrigare nv 20, Gravpräst nv 20
T8 Benfursten: Benstorm → alla | Arn −0 (barriär 19) | Brokk −25 | «Domens kall» | Benfursten −51 KRIT | Syster Alva −34 | Jäga…
T11 Arn: Rättfärdigt slag → Benfursten | Benfursten −128 | ‹Odödlig vrede›
T11 Benfursten: (artefakt) Benstorm → alla | Arn −15 (barriär 16) | Brokk −42 | «Domens kall» | Benfursten −25 | Syster Alva −5…
T13 Skelettkrigare: Benhugg → Syster Alva | Syster Alva −115 | «Domens kall» | Skelettkrigare −13 | Brokk står över (frozen)
T14 Benfursten: Väck de döda → Gravpräst | Gravpräst reser sig
!! Benfursten laddar Dödsdom – slår om 1 tur mot Syster Alva
!! Benfursten släpper Dödsdom!
T21 Benfursten: Dödsdom → Brokk | Brokk −431 | «Domens kall» | Benfursten −36
--- SEGER efter 31 turer ---
Kvar: Arn 579/579, Brokk 538/897, Syster Alva 402/406, Jägaren Eira 377/377
  avgjorde: [TROFÉ] Den återtända ljusstaken (Arn): 521 helning · 5 gånger
  avgjorde: [KALL] Domens kall (Arn): 331 skada · 11 gånger
  Brokk når nivå 18!
  Syster Alva når nivå 18!
  Jägaren Eira når nivå 18!
Fynd: 2 × Grön bärnsten (+Health), 1 × Blå bärnsten (+Intelligence), 1 × Järngrå bärnsten (+Defense), Styrkans skiffer (Trick: 15 % chans…
Lägret: 1) Det andra hugget; 2) Den slocknade glöden

> skip
=== Djupet är klarat! Ni går hem till borgen. ===
Kartan: fördärvet i Kryptan viker (1 → 0).
Kartan: fördärvet i Det fördärvade kapellet växer (1 → 2).
Medan ni var borta: Tors arbetare skickade en röd bärnsten från kryptan.
BORGEN – Arn, silver 493, perk-poäng 7/8 (Domens kall)
Vald nedstigning: Kryptan, djup 4 (klarat: Det fördärvade kapellet 2, Kryptan 4)
Djupets slut: huvudbossen
  Arn (paladin) nivå 18, trofé Den återtända ljusstaken, svärd nivå 6 (nästa 230 silver)
  Brokk (brokk) nivå 18, trofé Väktarens hjälm, sköld nivå 6 (nästa 230 silver)
  Syster Alva (alva) nivå 18, trofé Gravprästens radband, stav nivå 6 (nästa 230 silver)
  Jägaren Eira (eira) nivå 18, trofé Den kapade bågsträngen, stövlar nivå 5 (nästa 180 silver)
Värdshuset: imma (Imma, nivå 9), solveig (Solveig, nivå 8), tove (Broder Tove, nivå 7), sefir (Sefir av Sanden, nivå 2)

> trick arn 1 whetstone
Brynsten sitter nu i Arns artefakt.

> trick eira 1 curio_vulnerable
Sårbarhetens kuriosa sitter nu i Jägaren Eiras artefakt.

> smith eira
Smeden Hedda höjer Jägaren Eiras artefakt till nivå 6 (−180 silver). Troféplats

> arttrophy eira Bödelns_huva
Bödelns huva sitter nu i Jägaren Eiras artefakt (troféplatsen).

> depth 5
Djup 5 valt.

> start
=== Nedstigning 5: Kryptan, djup 5 ===
(Djupets väktare: Midnattsklockan)
Kryptan djup 5 – våning 1 av 2. Quest: Samla: ta 3 bevakade föremål (0/3)
     a  b  c  d  e  f  g  h
1   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~
2   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~
3   ~~ rr rr rr ~~ ~~ ~~ >*
4   ~~ rr rr rr ~~ ~~ ~~ ~~
5   ~~ rr rr rr rr rr ~~ ~~
6   ## ~~ rr rr rr rr ~~ ~~
7   @@ ## rr rr rr rr ~~ ~~
8   ## ~~ rr rr rr ~~ ~~ ~~
Sällskap: Arn nv 18, Charges 13/13, Den återtända ljusstaken · Brokk nv 18, Charges 10/10, Väktarens hjälm · Syster Alva nv 18, Charges 16/16, Gravprästens radband · Jägaren Eira nv 18, Charges 14/14, Den kapade bågsträngen

> go b7 c7 d7   (tomma rutor)

> go e7 e6 d6 d5 c5 c4
[FIENDEGRUPP] (Prästens nisch)
2 fiender: Skelettkrigare, Gravpräst
Vaktar ett av questens föremål.
  · Benrustning (Skelettkrigare)
  · Gravpakt (Gravpräst)

> fight
Strid: Prästens nisch – Skelettkrigare nv 22, Gravpräst nv 22
--- SEGER efter 6 turer ---
  Arn når nivå 19!
  Brokk når nivå 19!
  Syster Alva når nivå 19!
  Jägaren Eira når nivå 19!
Föremålet är ert. Samla: ta 3 bevakade föremål (1/3)
Lägret: 1) Det andra hugget; 2) Den slocknade glöden

> skip

> go d5 c5 c4 d4 d3
[FIENDEGRUPP] (Benkryptans gång)
2 fiender: Skelettkrigare, Skelettbågskytt
Vaktar ett av questens föremål.
  · Benrustning (Skelettkrigare)
  · Jägarblick (Skelettbågskytt)

> fight
Strid: Benkryptans gång – Skelettkrigare nv 22, Skelettbågskytt nv 22
--- SEGER efter 7 turer ---
Föremålet är ert. Samla: ta 3 bevakade föremål (2/3)
Lägret: 1) Det andra hugget; 2) Den slocknade glöden

> skip

> go d5 e5 f5 f6
Ni går till d5 (2 steg).
[FIENDEGRUPP] (Benkryptans gång)
2 fiender: Skelettkrigare, Skelettbågskytt
Vaktar en skatt.
  · Benrustning (Skelettkrigare)
  · Jägarblick (Skelettbågskytt)

> back
Ni backar till d5. Gruppen står kvar och spärrar rutorna intill sig.

> go e6 f6 f7
Ni går till e6 (2 steg).
[LÄGERELD] (vila +3 Charges en gång, eller byt troféer)

> choose 2

> go f7
[FIENDEGRUPP] (Prästens nisch)
2 fiender: Skelettkrigare, Gravpräst
Vaktar ett av questens föremål.
  · Benrustning (Skelettkrigare)
  · Gravpakt (Gravpräst)

> fight
--- SEGER efter 7 turer ---
Föremålet är ert. Samla: ta 3 bevakade föremål (3/3)
Questen är klar: +30 silver, och trappan är öppen!
Lägret: 1) Det andra hugget; 2) Den slocknade glöden

> skip

> go f6
[LÄGERELD] (vila +3 Charges en gång, eller byt troféer)

> choose 1
Lägerelden: +12 Charges. Här kan ni byta troféer.
  Brokk: ”Farfar brukade sitta så här efter gruvan. Han klagade också på veden.”

> go g6 g5 g4 h4 h3
[TRAPPAN] Questen är klar. Trappan leder ned till våning 2.

> choose 1
Spåren efter 1 grupper ni lät vara: +319 erfarenhet, +12 silver.
Ni går ned till våning 2.
Kryptan djup 5 – våning 2 av 2. Quest: Rensa: besegra 2 elitgrupper (0/2)
     a  b  c  d  e  f  g  h
1   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~
2   ~~ ~~ ~~ ~~ ~~ ~~ ~~ ~~
3   B* ~~ ~~ ~~ ~~ ~~ ~~ ~~
4   ~~ ~~ ~~ ~~ rr rr rr ~~
5   ~~ ~~ ~~ ~~ rr rr rr ~~
6   rr rr rr ~~ rr rr rr ##
7   rr rr rr ~~ ~~ ~~ ## @@
8   rr rr rr ~~ ~~ ~~ ~~ ##
Sällskap: Arn nv 19, Charges 13/13, Den återtända ljusstaken · Brokk nv 19, Charges 10/10, Väktarens hjälm · Syster Alva nv 19, Charges 14/16, Gravprästens radband · Jägaren Eira nv 19, Charges 14/14, Den kapade bågsträngen

> go g7 g6 f6 f5
  Brokk: ”Det där är dvärgarbete. Försiktigt med det, annars bär jag det själv.”
Skatt: +24 silver

> go f5 f4 e4 e5 e6
[ELITGRUPP] (Likfärden)
3 fiender: Kistbärare, Benspringare, Skelettbågskytt
  · Sista tjänsten (Kistbärare)
  · Flockbett (Benspringare)
  · Jägarblick (Skelettbågskytt)
Kan lämna: Kistspiken, Springarens steg, Den kapade bågsträngen

> fight
=== STRID: Likfärden ===
Fiender: Likbärare nv 25, Benspringare nv 25, Skelettbågskytt nv 25
!! Likbärare är en elitfiende
--- SEGER efter 19 turer ---
Kvar: Arn 607/607, Brokk 930/994, Syster Alva 442/448, Jägaren Eira 416/416
  avgjorde: [TROFÉ] Den återtända ljusstaken (Arn): 275 helning · 2 gånger
  avgjorde: [ARTEFAKT] Stav: Helande ljus (Syster Alva): 267 helning · 2 gånger
  Arn når nivå 20!
  Brokk når nivå 20!
  Syster Alva når nivå 20!
  Jägaren Eira når nivå 20!
LÄGRET (välj en trofé):
  1) Sista vaktens sköld [elite]
  2) Kistspiken
  3) Springarens steg
  4) Den slocknade glöden [common] – När någon i sällskapet helas får bäraren en Glöd (högst 5). Bärarens nästa förmåga förbrukar dem: +15 % skada per Glöd.

> skip

> go e5 d5 d6 c6 c7 b7 b6 a6 a7   (tomma rutor)

> go a8 b8 c8
[ELITGRUPP] (Dimmans valv)
3 fiender: Gravdimman, Skelettkrigare, Skelettbågskytt
  · Dimslöja (Gravdimman): Var tredje egen tur lägger Gravdimman hela sällskapet i Dimsömn i 1 tur (skada väcker inte).
  · Benrustning (Skelettkrigare)
  · Jägarblick (Skelettbågskytt)
Kan lämna: Den skingrade dimman, Det andra hugget, Den kapade bågsträngen
Motdrag – Gravdimman: era besvärjelser sänker sällskapets Intelligence 20 % i 2 turer.

> fight
=== STRID: Dimmans valv ===
Fiender: Gravdimman nv 25, Skelettkrigare nv 25, Skelettbågskytt nv 25
T5 Gravdimman: Dimslöja → alla | «Det brustna bönebandet» | Syster Alva står över (deep_sleep)
T8 Skelettkrigare: Benhugg → Jägaren Eira | Jägaren Eira −168 | «Domens kall» | Skelettkrigare −18 | Brokk står över (deep_slee…
T14 Brokk: Provocerar → Brokk | «Väktarens hjälm» | Arn +66 | «Räkenskap» | Skelettkrigare −21 | «Den återtända ljusstaken» | A…
--- SEGER efter 33 turer ---
Kvar: Arn 636/636, Brokk 1042/1042, Syster Alva 469/469, Jägaren Eira 436/436
  avgjorde: [TROFÉ] Den återtända ljusstaken (Arn): 542 helning · 4 gånger
  avgjorde: [KALL] Domens kall (Arn): 368 skada · 10 gånger
Questen är klar: +60 silver och en perk-poäng!
LÄGRET (välj en trofé):
  1) Den skingrade dimman [elite] – Bäraren kan inte sövas (inte heller Dimsömn). Bärarens första besvärjelse i striden söver målet i 1 tur.
  2) Det andra hugget
  3) Den slocknade glöden

> take 1
Ni tar med er Den skingrade dimman.

> go a7 a6 a5 a4 a3
  Syster Alva: ”Jag står där du kan hitta mig. Försök minnas det innan du behöver mig.”
[VÄKTARE] (Midnattsklockan)
Midnattsklockan: Klockaren vaktar djupet i bossens ställe.
Tre slag till midnatt: klockan väcker Benfolket, och det tredje slaget bryts bara om hela Benfolket har fallit.
4 fiender: Klockaren, Skelettkrigare, Benspringare, Gravpräst
Väktarens trofé: Midnattsklockans kläpp (2/2 segrar)
  · Resistent (Klockaren)
  · Klockslaget (Klockaren)
  · Benrustning (Skelettkrigare)
  · Flockbett (Benspringare)
  · Gravpakt (Gravpräst)
Motdrag – Klockaren: ni får bara väcka döda en gång per strid.

> fight
=== STRID: Midnattsklockan ===
Fiender: Klockaren nv 25, Skelettkrigare nv 25, Benspringare nv 25, Gravpräst nv 25
!! Klockaren laddar Klockan slår – slår om 1 tur
!! Klockaren släpper Klockan slår!
T8 Klockaren: Klockan slår → Klockaren
!! Klockaren laddar Klockan slår – slår om 1 tur
«Det brustna bönebandet»
!! Klockaren släpper Klockan slår!
T39 Klockaren: Klockan slår → Klockaren | Skelettkrigare reser sig
!! Klockaren laddar Midnatt – slår om 2 turer mot hela sällskapet (MIDNATT NÄRMAR SIG)
«Det brustna bönebandet»
--- SEGER efter 47 turer ---
Kvar: Arn 636/636, Brokk 906/1042, Syster Alva 469/469, Jägaren Eira 436/436
  avgjorde: [TROFÉ] Den återtända ljusstaken (Arn): 616 helning · 8 gånger
  avgjorde: [TROFÉ] Väktarens hjälm (Brokk): 462 helning · 7 gånger
  Arn når nivå 21!
LÄGRET (välj en trofé):
  1) Midnattsklockans kläpp [boss]
  2) Klockrepet [boss]
  3) Det andra hugget
  4) Springarens steg [common] – Bäraren börjar striden Smidig i 2 turer.

> skip
=== Djupet är klarat! Ni går hem till borgen. ===
Kartan: fördärvet i Det fördärvade kapellet växer (2 → 3).
Medan ni var borta: Tors arbetare skickade en järngrå bärnsten från kryptan.
Medan ni var borta: Nytt: Gravklockan ringer av sig själv. Klockan i kryptan ringer utan att någon drar i repet. Gå ned och slå tillbaka de döda som vaknar.
Kampanjkartan: Gravklockan ringer – slå fyra grupper där (två nedstigningar kvar)
BORGEN – Arn, silver 661, perk-poäng 7/9 (Domens kall)
Vald nedstigning: Kryptan, djup 5 (klarat: Det fördärvade kapellet 2, Kryptan 5)
Djupets slut: Midnattsklockan
  Arn (paladin) nivå 21, trofé Den återtända ljusstaken, svärd nivå 6 (nästa 230 silver)
  Brokk (brokk) nivå 21, trofé Väktarens hjälm, sköld nivå 6 (nästa 230 silver)
  Syster Alva (alva) nivå 21, trofé Gravprästens radband, stav nivå 6 (nästa 230 silver)
  Jägaren Eira (eira) nivå 21, trofé Den kapade bågsträngen, stövlar nivå 6 (nästa 230 silver)

```
