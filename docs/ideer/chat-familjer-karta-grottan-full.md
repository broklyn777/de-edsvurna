# De edsvurna – research K, L och M

Forskningsdatum: 22 oktober 2026. Underlag: de bifogade uppdragen och instruktionerna.

## Läsnyckel och avgränsning

- **SÄKERT** betyder att den angivna källan uttryckligen beskriver regeln eller den redovisade spelaråsikten. Det betyder inte att en spelares åsikt är representativ för alla.
- **TROLIGT** betyder en slutsats dragen från flera belägg. Slutsatsen är min, även när de bakomliggande reglerna är säkra.
- **GISSNING – DESIGNFÖRSLAG** betyder ett nytt förslag till De edsvurna. Procentsatser och andra balansvärden är testvärden, inte forskningsresultat.
- **SÄKERT – BERÄKNING** betyder en matematisk följd av uttryckligen angivna antaganden. Det är inte uppmätt spelarbeteende.
- Jag skiljer Siralim Ultimate från Siralim 1–3 och andra spels uppföljare. Aktuella wikis är inte automatiskt versionshistorik. Saknas en verifierad ändringsnotis anger jag inte när en regel infördes.
- Flera wiki.gg-sidor blockerade direktöppning. Där bygger faktaredovisningen på söktjänstens indexerade sidtext, med separat kontroll mot patch notes eller ytterligare källa när sådan fanns. Otestade detaljer anges som osäkra. Ingen privat Discord har lästs.
- Källorna är klickbara referenser sist i respektive faktapunkt eller tabellrad. Designförslag har inspirationskällor, men dessa belägger inte mina egna värden.

---

# K. Spindlar, kontroll, troll och återhämtning

## K1. Vilken kontroll finns faktiskt i Siralim Ultimate?

### Statusregler som behöver hållas isär

| Säkerhet | Effekt | Verifierad regel och betydelse | Källa |
|---|---|---|---|
| SÄKERT | Snared | Låser varelsen längst ned i Timeline. Vid början av **varje varelses tur** finns 10 % chans att komma loss; Resistant tredubblar chansen. Det är inte samma kontroll som att stå kvar i kön och missa sin handling. | [SU-debuffs] |
| SÄKERT | Frozen | Kan inte agera. Upptining prövas vid början av den drabbades tur: först 25 %, därefter dubblerad chans efter varje sådan tur. Resistant dubblerar upptiningschansen. | [SU-debuffs] |
| SÄKERT | Sleeping | Kan inte agera tills effekten löper ut eller varelsen tar skada. Standardduration 3 turer. Resistant vaknar i början av sin tur. | [SU-statusguide] |
| SÄKERT | Stone | Hindrar dodge och critical damage; standardduration 1 tur. Det är **inte** Petrified som gör enheten helt handlingsförlamad. | [SU-statusguide] |
| SÄKERT | Blind | Förlorad kontroll över målval vid Attack och single-target spells. Översätt inte automatiskt till en viss misschans. | [SU-blind] |
| SÄKERT | Scorned | Hindrar Attack; ersätter Silenced. Resistant får i stället 50 % lägre attack damage. Ett exempel på att behålla ett försvagat handlingsalternativ. | [SU-scorned] |
| SÄKERT | Taunting | En buff som automatiskt utlöser Provoke vid slutet av bärarens tur. Ska inte beskrivas som en separat Stun på motståndaren. | [SU-buffs] |

- **SÄKERT:** Debuff-immunitet hindrar applicering. Att återapplicera en potency-baserad debuff summerar inte automatiskt styrkorna; högsta potency används. Därför måste en faktisk förstärkning skiljas från en ny applicering. [SU-status]
- **TROLIGT:** För ert Timeline-system är skillnaden mellan ”flytta bak”, ”håll kvar längst bak” och ”förlora nästa handling” viktigare än namnet på kontrollen. De skapar olika räddningsfönster och olika risk för permanent låsning. [SU-debuffs], [SU-statusguide]

### Varelser och familjer med tydliga kontrollroller

| Säkerhet | Varelse/familj | Trait eller regel | Vad spelaren bygger kring | Källa |
|---|---|---|---|---|
| SÄKERT | Goliath Arachnalisk | Entrapment: efter att varelsen blivit Attacked får angriparen Snared. | Reaktiv kontroll på en enhet som tar emot attacker. | [SU-arach] |
| SÄKERT | Dragonlair Arachnalisk | Numbing Venom: Poisoned-skada har 50 % chans att ge Snared; staplas inte. | Kopplingen mellan skademotor och kontroll. | [SU-dragonlair] |
| SÄKERT | Canopy Arachnalisk | Here to Die: när fienden får Bleeding eller Poisoned appliceras den andra, om den saknas. | En applicering etablerar två kombovillkor. | [SU-arach] |
| SÄKERT | Woolly Arachnalisk | Arachnophobia: Snared-fiender tar 100 % mer Poisoned-skada; frigörelse ger skada motsvarande 5 poison-turer. | Kontroll får en skadeutbetalning även när den bryts. | [SU-woolly] |
| SÄKERT | Ancient Arachnalisk | Consume: Attack mot Snared ger +150 % skada, helar för 100 % av skadan och tar bort Snared. | Aktivt val mellan fortsatt kontroll och att konsumera den. | [SU-ancientarach] |
| SÄKERT | Razorweb Arachnalisk | Jagged Edges: vid början av varje varelses tur tar Snared-fiender skada motsvarande 10 % av bärarens Speed; staplas inte. | En skadeklocka som inte kräver fiendens egen handling. | [SU-razorweb] |
| SÄKERT | Arachnalisk Mastery | Poisoned-skadan ökar 20 % per allierad Arachnalisk; staplas inte. | Ett uttryckligt exempel på familjeräkning. Senare 2.0.38-notis rapporterar en buggfix för vilken sida Mastery gynnar. | [SU-arach], [SU-hotfix] |
| SÄKERT | Frostbite Yeti | Brain Freeze: angriparen får Frozen efter att ha Attacked bäraren. | Reaktivt stopp för attackerare. | [SU-sorcerer] |
| SÄKERT | Yeti Mastery | Alla fiender börjar Frozen om hela den egna gruppen är Yetis. | Familjekrav köper en stark öppning. | [SU-yetisigil] |
| SÄKERT | Siren Coercer | Forbidden Lullaby: angriparen får Sleeping efter att ha Attacked bäraren. | Sömn som motanfall, snarare än ännu ett aktivt kommando. | [SU-siren] |
| SÄKERT | Marionette Hypnotist | Efter att en fiende Defends får den Blind och Sleeping. | Bestraffar en viss handling. | [SU-marionette] |
| SÄKERT | Exiled Satyr | Languid Limbs begränsar fiender till en Attack åt gången. | Bryter multistrike-motorer utan att förbjuda samtliga handlingar. | [SU-satyr] |
| SÄKERT | Sorcerer | Slipstream flyttar egna varelser uppåt i startordningen, upp till 3 positioner. | Kontroll över vem som får etablera sin motor först. | [SU-sorcerer] |

### Dokumenterade kontrollbyggen: motor, utdelning och möjliggörare

- **SÄKERT – versionsändring i 2.0:** Arachnophobia höjdes från 65 % till 100 % extra giftskada och fick utbetalningen motsvarande 5 poison-turer när fienden bryter sig loss. Äldre 65 %-tabeller beskriver alltså inte den uppdaterade effekten. [SU-patch]
- **SÄKERT – dokumenterat, inte popularitetsrankat:** Toxicologist-byggen med Arachnalisks finns i spelarnas byggdiskussioner. **TROLIGT – mekanisk analys:** giftet är motorn, Snared skapar kontroll, Arachnophobia ger utdelning. Men ett giftbygge måste ha en faktisk väg att utlösa giftskada; anta inte att en Snared-fiende fortsätter få vanliga egna turer. [SU-toxicbuild], [SU-arach], [SU-woolly]
- **SÄKERT:** Deep Freeze ger varje fiende 50 % chans till Frozen och ger Snared om Frozen applicerades eller redan fanns. **TROLIGT:** tidig spellcasting och återkommande applicering kan etablera ett kontrollås; två kontrolltyper gör inte i sig bygget säkert mot immunitet eller motmekanik. [SU-deepfreeze], [SU-freezebuild]
- **SÄKERT:** Defiler har Infirmity, upp till 3 slumpmässiga startdebuffs, och Lingering Sickness, som gör fiendens debuffs permanenta. Kombinationen rekommenderas i spelartrådar. **TROLIGT:** bygget får bred störning tidigt, men slumpad debuff är inte garanterad hard CC och permanent duration är inte bevis för att specialregler för frigörelse slutar gälla. [SU-defiler], [SU-defilerplayers]
- **SÄKERT:** Mesmerist tillkom i 2.0 med fokus på kontroll, särskilt Sleep. Aktuell wikitext anger Oneirophrenia till **50 %** chans för Sleeping-resistant fiender att förlora sin tur; ett äldre förhandsinlägg anger 60 %. Använd inte förhandsvärdet som aktuell regel. [SU-patch], [SU-mesmerist], [SU-mesmeristpreview]
- **Begränsning:** Jag kan belägga att dessa upplägg används och diskuteras. Jag kan inte belägga att de är de mest spelade CC-byggena; det saknas representativ statistik i det granskade materialet.

## K2. Hur blir kontroll mot spelaren uthärdlig?

| Spel och version | SÄKERT – konkret regel | TROLIGT – designlärdom | Källa |
|---|---|---|---|
| Siralim Ultimate | Resistant försvagar effekten på olika sätt: snabbare frigörelse eller möjlighet att agera med sänkt effekt. Immunitet är en annan regel. | En gemensam ”50 % CC-resist”-etikett skulle dölja viktiga skillnader. | [SU-debuffs], [SU-scorned] |
| Darkest Dungeon 1 | Efter att Stun kostat en handling får enheten +50 procentenheters Stun resistance i 1 tur. | Tillfälligt skydd gör upprepad kontroll svårare utan permanent immunitet. Det är ingen garanti att nästa Stun misslyckas. | [DD-stun] |
| Slay the Spire 1 | Entangled förbjuder Attack-kort under turen; Skills och Powers är andra kategorier. Artifact negerar nästa debuff-applicering per stack. | Kontroll kan tvinga omplanering utan att stänga av hela spelarens tur. | [STS-debuffs], [STS-artifact] |
| Into the Breach | Webbing hindrar rörelse; förflyttning genom push kan bryta situationen. Spelaren kan granska attackordningen. | Ge andra gruppmedlemmar ett sätt att rädda den låsta. Blockerad rörelse är inte förlorad vapenhandling. | [ITB-status], [ITB-guide] |
| Pokémon, huvudserien Gen VII–IX | Sleep varar 1–3 turer; paralysis ger normalt 25 % risk att inte kunna agera och halverad Speed. Freeze har 20 % naturlig upptining per tur i Gen III–IX. | Kort varaktighet begränsar Sleep, men Freeze visar att en låg konstant frigörelsechans ändå kan ge långa låsningar. Detta är inte en generell anti-chain-regel. | [PK-sleep], [PK-paralysis], [PK-freeze] |
| Octopath Traveler 1 | Weakness-träffar minskar Shield Points. Break tar bort återstoden av den aktuella rundans handlingar och nästa rundas handlingar; fienden återhämtar sig först i följande runda. | Ett synligt arbete före kontrollen och en bestämd återhämtning gör fönstret planeringsbart. Detta gäller här kontroll av fiender, inte en generell regel för alla statusar mot hjältar. | [OT-break], [OT-system] |
| Wildfrost | Resist Snow begränsar Snow till 1 stack. Utvecklaren beskrev ändringen från full Snow-immunitet till resistens för bossar/minibossar. | Även en kontrollspecialist får bidra mot bossar, men obegränsad lagring av kontroll stoppas. | [WF-dev], [WF-resist] |

- **SÄKERT:** Wildfrosts Snow stoppar även räknarens normala progression medan effekten gäller; 1 Snow är därför inte samma sak som att nollställa en fiendes attacktimer. [WF-snow]
- **TROLIGT:** De återkommande mönstren är begränsad varaktighet, alternativa handlingar, allierad räddning och tydlig information. Beläggen stödjer inte att alla jämförelsespel har diminishing returns eller immunitet efter kontroll. [DD-stun], [STS-debuffs], [ITB-status], [WF-dev]
- **GISSNING – DESIGNFÖRSLAG:** I ett fyrmannalag kostar en förlorad hjältehandling en av fyra nominella aktörers bidrag. Testa därför högst en hard-CC-fiende i tidiga grupper och förvarna om dess mål. Effekten beror på faktisk handlingsfrekvens, så ”25 % av laget” är inte automatiskt ”25 % av lagets styrka”. Inspiration: [ITB-guide], [DD-stun].

## K3. Återhämtande fiender som skapar beslut

| Spel | SÄKERT – exempel | TROLIGT – beslutet det skapar | Källa |
|---|---|---|---|
| Siralim Ultimate | Ebony Ent ger ständig Mending och 15 % lägre inkommande skada; Hemlock Ent helar 15 % vid egen turstart, eller 50 % om Mending finns. | Ta bort möjliggöraren eller fokusera ned en fiende före dess återhämtning. Spridd skada blir mindre effektiv. | [SU-ent] |
| Siralim Ultimate | Blighted hindrar healing och gör healing till skada motsvarande 50 % av effekten. | Återhämtning kan bli en svaghet som laget utnyttjar. | [SU-blight] |
| Slay the Spire 1 | Mystic helar alla fiender för 16 HP, 20 på A17+. Dess healingval styrs av saknat HP och kan användas högst två gånger i följd. | Trösklar och handlingsval gör det möjligt att planera fokuserad skada och nästa healingfönster. | [STS-mystic] |
| Darkest Dungeon 1 | Pelagic Shaman kan både hela, buffa och orsaka stress. Om en annan fiende är under 70 % HP finns 1/5 chans att välja Sea Breeze. | Healerrollen konkurrerar med andra hot; den är inte bara gratis återhämtning ovanpå full offensiv. | [DD-shaman] |
| Into the Breach | Blood Psion ger andra Vek återhämtning på 1 HP per tur. | Döda källan, döda en skadad fiende direkt eller välj displacement när dödande inte behövs. | [ITB-status], [ITB-blood] |
| Final Fantasy X | Yunalescas Absorb kan skada för halva offrets max-HP och hela bossen lika mycket. Zombie förändrar healinginteraktionen. | Samma handling kopplar samman överlevnad och bossens uthållighet. Referensen gäller mekanik; dess tema behövs inte i ert spel. | [FF-yunalesca] |
| Monster Train 1 | Trial Heaven’s Seal återställer non-boss-fienders HP när de flyttar upp en våning. | Döda på en våning eller samla skada på en senare. Små träffar över flera våningar kan försvinna helt. | [MT-trials] |

- **SÄKERT:** Monster Train 1:s Restoration Detonation helar 10 och skadar främsta fienden för 5 gånger faktisk healing. Spelare beskriver begränsningen när det saknas skadade egna mål. Det är ett exempel på healing som offensiv resurs, inte en regenererande fiende. [MT-detonation], [MT-players]
- **TROLIGT:** Healing skapar beslut när spelaren kan påverka **källa, tidpunkt, mål eller omvandling**. En ständig lika stor återbetalning av all skada, utan motdrag, riskerar bara att förlänga striden. Jämförelserna ovan visar olika vägar till motdrag. [SU-ent], [STS-mystic], [MT-trials]
- **GISSNING – DESIGNFÖRSLAG:** Låt trollens regeneration komma vid egen turstart. Visa i avsikten vem de därefter tänker hela. Då kan ett lag välja mellan burst, kontroll av healer eller ljus mot regeneration. Ge tidiga lag minst två tillgängliga lösningar; gör inte ett specifikt ljusanfall till en okänd obligatorisk nyckel.

## K4. Traits som gör en annan varelse till healer eller support

| Säkerhet | Trait | Vad en enda bärare tillför | Källa |
|---|---|---|---|
| SÄKERT | Nature’s Blessing, Ebony Ent | Hela gruppen har Mending och tar 15 % mindre skada; staplas inte. | [SU-ent] |
| SÄKERT | Nutrient Blood, Hemlock Ent | Gruppens egen turstart helar 15 % HP, eller 50 % med Mending; staplas inte. | [SU-ent] |
| SÄKERT | Mender’s Oath, Nephilim Cleric | Egna healinghändelser helar övriga allierade för 25 % av mängden; gruppen får samtidigt 50 % mindre healing. Staplas inte. | [SU-nephilim] |
| SÄKERT | Charity, Caritas Sanctus | När bäraren helas helar den en annan allierad för 300 % av mängden. Kan inte hela någon som också har Charity. | [SU-caritas] |
| SÄKERT | Abnegation, Clairvoyant Spirit | Egna healinghändelser skadar en slumpad fiende för 50 % av återvunnet HP; staplas inte. Healer blir även skadebidrag. | [SU-clairvoyant] |
| SÄKERT | Carnal Genesis, Succubus Spirit | Efter egen healing har den helade 10 % chans att flyttas till Timeline-toppen; staplas inte. | [SU-succubus] |
| SÄKERT | Overheal, Cleric Perk | Tillåter healingtriggers även vid fullt HP. Detta är en **Perk/Anointment-kandidat**, inte en vanlig creature Trait. | [SU-cleric] |

### Starka loopar och vad som faktiskt är känt om begränsningar

- **SÄKERT:** En publicerad Cleric-guide för **1.1.1** bygger runt Mender’s Oath, Charity, Willow Spirit och Cleric-perks. Det är belägg för en historisk fungerande byggidé, inte ett fullständigt 2.0-test. [SU-clericguide]
- **SÄKERT:** Nuvarande Trait-text har både Mender’s Oaths healingstraff och Charitys förbud mot att hela andra Charity-bärare. **Vet inte:** jag har inte belagt att just dessa begränsningar infördes som en viss daterad nerf. [SU-nephilim], [SU-caritas]
- **SÄKERT:** Combat-reglerna beskriver normalt högst 15 händelser per varelse, kategori och tur för bland annat mottagen healing. Förflyttning till Timeline-toppen återställer turgränserna. Därför är ett tak per tur inte ett säkert tak för en hel strid. [SU-combat], [SU-faq]
- **SÄKERT – spelarobservation:** Det finns rapporter om healingloopar med Timeline-förflyttning som håller spelaren borta från nya beslut under lång tid. **Vet inte:** det granskade underlaget visar ingen verifierad patch som generellt avskaffat alla sådana loopar. [SU-healloop], [SU-loopdiscussion]
- **SÄKERT – 2.0:** Relics undantogs från flera turgränser, inklusive mottagen healing. Calm Mode lades till som alternativ med färre möjliga stridshandlingar. Detta är inte belägg för en specifik Abnegation-nerf. [SU-patch]
- **GISSNING – DESIGNFÖRSLAG:** Låt inte trolltroféer både skapa healing, förstärka samma healing och ge nya turer utan ett gemensamt kedjetak. Använd faktiskt återställt HP för skadeomvandling och skilj på ursprunglig healing och utlöst healing. Inspiration: [SU-combat], [SU-healloop], [MT-detonation].

## K5. Två föreslagna familjer – sex fiender och sex troféer vardera

**Allt i K5 är GISSNING – DESIGNFÖRSLAG.** Namn, värden och statuskontrakt är nya förslag. Era befintliga definitioner måste ersätta mina testdefinitioner innan implementation.

### Gemensamma testregler

- **Familjeräkning:** F är antalet levande allierade i den aktuella familjen, inklusive bäraren. För hjältar räknas en hjälte som familjemedlem när minst en utrustad trofé tillhör familjen. Två spindeltroféer på samma hjälte räknas fortfarande som **en** spindelmedlem. En hjälte kan räknas i båda familjerna. Detta tillför ingen grund-Trait till hjälten.
- **Troféer:** Varje fiende nedan släpper sin namngivna trofé, som ger exakt dess angivna Trait. Familjeetiketten följer trofén; kopior av samma Trait på en bärare staplas inte. Individuella effekter fungerar på varje bärare, men identiska gruppauror dubblerar inte samma händelse. En trofé fungerar ensam med F=1.
- **Statusar för testet:** Marked och Blinded är befintliga kombotaggar vars vanliga effekt inte ändras här. Poisoned och Bleeding har sina vanliga skadetick. Sleep stoppar nästa egna handling och bryts av HP-skada. Snared flyttar till köns slut och tas bort efter en missad egen handling. Denna korta Snared är **avsiktligt inte Siralims regel**.
- **Skydd mot kedjelåsning:** Efter en förlorad handling från Sleep/Snared får målet genomföra en egen handling innan någon av dem åter kan kosta en handling. Applicering får fortfarande ske för kombovillkor. På minibossar blir ny Sleep/Snared under skyddet endast en förflyttning ned **en** köposition, högst en gång mellan bossens egna handlingar; ingen ny förlorad handling.
- **Triggertak:** Varje reaktiv Trait aktiveras högst en gång mellan bärarens egna turstarter om inget annat står. Applicering kräver att målet faktiskt får statusen; en blockerad applicering räknas inte. Healing till fullt HP ger ingen ”återställt HP”-utdelning.
- **Ljus och troll:** Troll som fiendeart har en separat familjesvaghet: efter en ljusträff fungerar deras Trait-baserade healing inte förrän efter deras nästa egna tur. Vanliga healingförmågor fungerar fortfarande. Hjälten som bär trofén får inte denna artsvaghet. Visa skillnaden mellan **artregel** och den **Trait** som trofén ger. Detta undantag måste stå i inspektionen.

Inspiration till familjeräkning: [SU-arach]. Inspiration till kontrollerad CC: [DD-stun], [WF-dev]. Inspiration till healingbegränsningar: [SU-nephilim], [SU-caritas], [SU-combat].

### Spindlar – läs vem som lägger villkoret och vem som skördar det

| ID, fiende och roll | Trait – samma text gäller trofébäraren | Trofé | Två-Trait-kombination och motdrag |
|---|---|---|---|
| S1 **Snärjspindel** – kontrollöppnare | **Fästtråd:** Första gången bäraren skadar en fiende med en Attack mellan egna turstarter får målet Snared. | Trådspole | + S2: snärjningen förstärker giftmotorn. Motdrag: skydda den utsatta hjälten eller kontrollera spindeln först. |
| S2 **Bärgiftsspindel** – giftspridare | **Gift i tråden:** När en fiende får Snared applicerar bäraren Poisoned på den med normal grundstyrka. Om Poisoned redan finns ökas dess styrka med **5 % × F**, högst 20 %. | Bärgrön gifttand | + S1: Attack → Snared → Poisoned. Motdrag: rena gift eller stoppa öppnaren. |
| S3 **Dammspindel** – stör målval | **Damm över ögonen:** Efter bärarens Attack mot en Poisoned-fiende får målet Blinded till efter nästa egen handling. | Dammtofs | + S2: gift möjliggör blindhet; fungerar utan att bäraren själv lägger giftet. Motdrag: välj förmåga som inte kräver valt mål, om era regler tillåter det. |
| S4 **Taggtrådsspindel** – skadar den som försöker slå sig fri | **Hullingar:** När en Blinded-fiendes Attack orsakar HP-skada på en allierad får angriparen Bleeding med normal grundstyrka. | Hullingtråd | + S3: gift → blindhet → blödning när fienden träffar. Motdrag: använd annan handling medan Blinded. |
| S5 **Sömnvävare**, elit – förbereder ett offer | **Vaggande nät:** När bäraren skadar en Marked-fiende med Attack får målet Sleep. Avsikten visar mål och Sleep före handlingen. | Mjuk nätkudde | + S6: Marked möjliggör Sleep. Motdrag: ta bort Marked eller bryt elitens plan; Sleep skyddas av gemensamma låsregler. |
| S6 **Gamla Knut**, miniboss – väljer nästa offer | **Trådens slut:** Vid bärarens turstart får den icke-Marked-fiende som står högst i kön Marked till efter dennes nästa egen handling. Bärarens attacker mot Marked gör **5 % × F** mer skada, högst 20 %. | Knutens öga | + S5: bäraren förbereder målet som sömnvävaren sedan kan låsa. Motdrag: växla försvar och avlägsna märket före sömnslaget. |

- **GISSNING – DESIGNFÖRSLAG, grupp 1:** S1 + S2 + två enkla fiender lär ut ”snärjning föder gift”. Lägg inte till Sleep här.
- **GISSNING – DESIGNFÖRSLAG, grupp 2:** S2 + S3 + S4 visar en trestegsmotor, men dess första fiendehandlingar måste själva kunna starta Poisoned genom en tydligt annonserad förmåga. Traits är inte automatiskt hela fiendens handlingslista.
- **GISSNING – DESIGNFÖRSLAG, minibossgrupp:** S6 + S5 + en försvarare. Märket visas före elitens tur; spelaren ser hotkedjan i avsikterna.
- **GISSNING – DESIGNFÖRSLAG, balansrisk:** S2 ska förstärka vid faktisk ny Snared-applicering, inte vid varje statuskontroll. Annars kan nät och gift skala utan nya beslut. Inspirationsmönster: [SU-arach], [SU-status].

### Troll – troféerna gör bäraren till en möjlig healer

| ID, fiende och roll | Trait – samma text gäller trofébäraren | Trofé | Två-Trait-kombination och motdrag |
|---|---|---|---|
| T1 **Mossrygg** – grundläggande regenererare | **Mossplåster:** Vid egen turstart återfår bäraren **2 % × F** av max-HP, högst 8 %. Har någon fiende Poisoned helas även den mest skadade andra allierade för samma procent av mottagarens max-HP. | Mjuk mossbit | + S2: Poisoned öppnar grupphealing. Motdrag: burst före turstart eller ljus mot Trait-healing. |
| T2 **Sårknutstroll** – bandagerare | **Knyt om:** Vid egen turstart tar bäraren bort Bleeding från den allierade med lägst HP-andel och helar den för **3 % × F** max-HP, högst 12 %. Kräver att Bleeding togs bort. | Trollbandage | + T6: T6 lägger Bleeding och skapar en kostnad som T2 kan lösa. Motdrag: stoppa bandageraren i rätt ögonblick. |
| T3 **Rotvakt** – försvarare som läker andra | **Rotvila:** Efter att bäraren Defends får den mest skadade allierade 8 % max-HP i healing om någon fiende är Snared. | Rotknapp | + S1: snärjning gör Försvara till en healinghandling. Motdrag: kontrollera Rotvakt eller låt inte öppnaren etablera Snared. |
| T4 **Dimmullstroll** – läker när fienden störs | **Andrum:** När en fiende får Blinded helas den mest skadade allierade för 8 % max-HP. | Dimmull | + S3: blindhet ger healing utan separat healingkommando. Motdrag: rena villkoret och prioritera kontrollkällan. |
| T5 **Trollmor Gråluva**, elit – använder sovfönstret | **Lugn och ro:** När en fiende får Sleep helar bäraren den mest skadade allierade för 10 % max-HP och tar bort Poisoned från samma mottagare. | Gråluvans nål | + S5: sömn blir ett räddningsfönster för egen grupp. Motdrag: avvärj den annonserade Sleep-appliceringen. |
| T6 **Brom, broarnas väktare**, miniboss – riskhealer | **Dela bördan:** Efter bärarens Attack mot Marked helas den mest skadade andra allierade för 10 % max-HP. Den helade får därefter Bleeding med normal grundstyrka. | Broms brospänne | + S6: märket möjliggör healing. + T2: bandagering hanterar kostnaden. Motdrag: ta bort Marked eller slå ut bandageraren före nästa återhämtning. |

- **GISSNING – DESIGNFÖRSLAG, grupp 1:** Två T1 + två vanliga angripare visar familjeräkning men har ingen oändlig grupphealing utan Poisoned. Högst en gemensam trigger per identisk Trait förhindrar dubblerad aura.
- **GISSNING – DESIGNFÖRSLAG, grupp 2:** T3 + S1 + två angripare: spindeln skapar den säkra vilan. Spelaren kan bryta kedjan genom att angripa endera länken.
- **GISSNING – DESIGNFÖRSLAG, minibossgrupp:** T6 + T2 + en fiende med tydlig Marked-förmåga. Både kostnad och kommande bandagering visas. Ingen osynlig gratis självläkning ovanpå det.
- **GISSNING – DESIGNFÖRSLAG:** Varje trolltrofé gör bäraren till en faktisk healingkälla under ett begripligt villkor. T1–T2 visar familjeräkning. Alla sex spindeltroféer och alla sex trolltroféer har minst en explicit två-Trait-koppling; tillsammans täcker de Poisoned, Snared, Blinded, Bleeding, Marked och Sleep.
- **GISSNING – DESIGNFÖRSLAG, viktig testfråga:** Familjeräkning konkurrerar här med blandfamiljekombos om fyra hjälteplatser. Jämför ett rent trollag med två trolltroféer + två spindeltroféer; låt inte F-bonusen ensam slå ut hela komboutbudet.

---

# L. Den levande kartan

## L1. Vilka spel har en värld som reagerar på handling och försummelse?

| Spel | SÄKERT – vad ändras och hur syns det? | TROLIGT – relevans för er karta | Källa |
|---|---|---|---|
| XCOM 2 | Avatar Project fyller 12 block och går sedan över till en förlustnedräkning. Angrepp på anläggningar och vissa uppdrag minskar framstegen. | En tydlig global hotklocka, men inte ett ekologiskt familjesystem. | [XC-avatar], [XC-ufo] |
| Shadow of Mordor | En vanlig Uruk som dödar spelaren kan bli kapten; nemeses växer i makt och kommenterar tidigare möten. Arméhierarkin och den namngivna individen visar förändringen. | Låt en återkommande miniboss få namn och ett minne av spelarens val. | [NEM-manual] |
| Shadow of War | Nemesis-missioner och avancemang i tid förändrar kaptenernas nivåer och konflikter. Death Threat kan höja en kapten 5 nivåer inför en bättre belönad jakt. | Aktivt accepterad upptrappning är tydligare än en osynlig passiv straffkurva. | [NEM-tips], [NEM-threat], [NEM-gear] |
| Battle Brothers | Late-game crises hotar bosättningar. Permanent Destruction kan stängas av; då ersätts förstörelse av tillfälliga tillstånd. | Separera dramatisk skada från permanent förlust av spelarens innehåll. | [BB-dev], [BB-crisis] |
| Darkest Dungeon 1 | Hamlet får Town Events; Crimson Court har Low/Moderate/High infestation som ökar möten utanför Courtyard. | Namngivna tillstånd kan uttrycka tryck utan procentmätare. Inte ett allmänt kretslopp mellan alla fiendefamiljer. | [DD-events], [DD-courtyard] |
| Darkest Dungeon II – Confessions | Flame och Loathing förändras under expeditionen och påverkar dess hotbild. Flame mäts 0–100. | Bra referens för hotåterkoppling, men inte en permanent territoriell värld mellan alla runs. | [DD2-flame], [DD2-loathing] |
| Darkest Dungeon II – Kingdoms | Ett separat läge med Inns, försvar, belägringar och eskalation under kampanjen. | Närmare er idé än Confessions: flera platser behöver uppmärksamhet, och lokal försvarsförmåga spelar roll. | [DD2-kingdoms], [DD2-review] |
| Mount & Blade: Warband | Plundrade byar ryker på världskartan och återgår senare till verksamhet. | Rök och frånvarande vardagsliv kan visa en ekonomisk förändring utan att vara en mätare. | [MB-villages] |
| Mount & Blade II: Bannerlord | Byproduktion, handel och krig kopplas samman; byars resurser är knutna till fästen. | En handling kan påverka en närliggande plats genom en begriplig försörjningsrelation. Undvik att överföra Warbands exakta återhämtningstal till Bannerlord. | [MB-dev] |
| Wildermyth | Infestation sprids över territorier; incursions kan härja platser. Försvar bromsar och förbrukar invasionens styrka. | Starkast direkt förebild för karta, försvar, upptrappning och återhämtning. | [WILD-infest], [WILD-redesign] |
| Into the Breach | Inom en kampanj väljs öar och uppdrag; svårigheten följer antalet avslutade öar. Finalen kan nås efter 2 öar. | Förebild för att välja nästa prövning, inte belägg för att försummade öar autonomt odlar starkare familjer. | [ITB-guide], [ITB-islands] |
| Hades | Hubben förändras genom Contractor-köp och karaktärsreaktioner; dialog kan reagera på senaste döden. | Världen kan kännas levande genom igenkänning och återkomst, även utan territoriell simulering. | [HADES-dev], [HADES-dialogue] |
| Inscryption – Act I | Kartan startas om efter död, men vissa upplåsningar och stugpussel består; Deathcards kan dyka upp senare. | En kvarstående konsekvens mellan försök, inte en karta där alla områden fortsätter växa. Kaycee’s Mod har andra regler. | [INS-reset], [INS-deathcard] |
| Dominions 6 | Provinser påverkas av Dominion, scales, befolkning och unrest. Egen Dominion visas med vita ljus, främmande med mörka. | Visuellt inflytande kan vara tydligt, men bakom ljusen finns exakta värden och komplicerade system. | [DOM-manual] |
| Fear & Hunger 2: Termina | Sömn för sparande driver normalt den begränsade tredagarscykeln framåt; karaktärer och möjligheter förändras med tiden. Vissa andra sparmetoder undviker tidssteg. | Studera fasta, handlingsutlösta tillståndsskiften. Temat och hårdheten behövs inte i ert spel. Detta är en tidslinje inom genomspelningen. | [FH-save], [FH-characters] |

### Vad spelare faktiskt säger

- **SÄKERT – avgränsad spelaråsikt:** Nemesis-trådar innehåller berättelser om specifika återkommande kaptener och långvariga följeslagare. **TROLIGT:** identitet och igenkänning står för en stor del av upplevelsen av liv; fler simuleringstal är inte den enda vägen dit. [NEM-players]
- **SÄKERT – avgränsad spelaråsikt:** XCOM-spelare beskriver stress över risken att förlora en lång kampanj, medan andra rekommenderar att planera kring nedräkningen. Det är belägg för olika reaktioner, inte för en gemensam preferens. [XC-players], [XC-planning]
- **SÄKERT – avgränsad spelaråsikt:** En Wildermyth-spelare efterfrågar avstängd eller långsammare hotklocka för att hinna se fler berättelsehändelser. [WILD-players]
- **SÄKERT – avgränsade spelaråsikter:** Kingdoms har både trådar som uppskattar läget och kritik mot många belägringar och repetitiv administration. **TROLIGT:** ett levande lager kan börja konkurrera med det spelaren egentligen kom för. [DD2-positive], [DD2-chore]
- **SÄKERT – avgränsad spelaråsikt:** Battle Brothers-forum innehåller motstånd mot att en sandbox blir ett kapplöpande mot klockan och önskemål om att slippa permanent förstörelse. [BB-players]
- **Begränsning:** Jag har inte gjort en representativ analys av spelaromdömen för vart och ett av de femton jämförelsefallen. Särskilt Dominions, Inscryption och Into the Breach används här som mekanikjämförelser; jag tillskriver dem ingen påhittad spelarkonsensus.

## L2. Hur visas tillstånd utan procentmätare?

| Informationsbehov | SÄKERT – förebild | GISSNING – DESIGNFÖRSLAG till De edsvurna | Källa |
|---|---|---|---|
| Vad har hänt? | Warbands plundrade byar ryker. | Rök, stängda fönster, tom väg och nedbränd gärdsgård visar en angripen plats. | [MB-villages] |
| Hur allvarligt är det? | Crimson Court använder Low/Moderate/High. | Tre tydliga bildstadier: färska spår → tät närvaro → svarta märken. Lägg en kort tillståndstext i inspektionen. | [DD-courtyard] |
| Vem påverkar platsen? | Dominions använder ljusfärg och Dominion-information. | Spindelnät, trollens stenrösen eller skelettens brutna sköldar visar familjen. Använd form och symbol utöver färg. | [DOM-manual] |
| Vad kan jag göra? | Wildermyth visar försvar med 1–3 sköldsymboler och har synliga invasioner. | Visa hotets källa och vart det påverkar med en kort animerad markering när spelaren återvänder. | [WILD-redesign] |
| Minns världen mig? | Hades har situationsberoende dialog. | Imma: ”Sist var här bara några trådar. Nu har de börjat möblera.” En kommentar endast när tillståndet ändras. | [HADES-dialogue] |
| När måste jag agera? | Wildermyth lade till tidsindikatorer för nästa Calamity och Incursion. | Behåll kartan utan mätare men skriv ”Väntar ni en expedition till visar sig ledaren” före sista övergången. | [WILD-timers] |

- **TROLIGT:** Spelaren behöver inte veta ”korruption 73 %”, men behöver kunna skilja ”kan vänta” från ”nästa expedition ändrar detta”. Att dölja den skillnaden gör ett strategiskt beslut till en gissning. [WILD-timers], [XC-players], [DD2-review]
- **GISSNING – DESIGNFÖRSLAG:** Före avfärd visas en konkret konsekvensrad: ”Om ni går till bron: trollen trycks tillbaka. Skeletten vid kryptan får mer spelrum.” Efter återkomst visas samma orsak med förändringen. En mörkare fläck ensam förklarar inte orsak och verkan.
- **GISSNING – DESIGNFÖRSLAG:** Låt spelaren återöppna den senaste rapporten. Dialog får inte vara den enda plats där en viktig regel framgår, och tända vårdkasar ska även ha en tydlig formskillnad.

## L3. Att låta ett hot växa – belöning utan en fälla

- **SÄKERT:** Shadow of War låter Death Threat höja målet 5 nivåer inför jakten. Supportinformationen bekräftar att gear främst kommer från kaptener och uppdrag. Det ger ett konkret system för självvald svårare belöning. Den exakta ökningen av Epic-dropchans är inte verifierad här. [NEM-threat], [NEM-gear]
- **SÄKERT:** Loop Hero ökar både Enemy- och Equipment-level när ett nytt varv börjar. Normal återkomst vid lägerelden behåller 100 % resurser, reträtt ute på loopen 60 %, död normalt 30 %. Det är risk under en expedition, inte en värld som växer mellan alla runs. [LOOP-camp], [LOOP-retreat]
- **SÄKERT:** XCOMs fördröjning kan köpa förberedelsetid, men Avatar Project är inte ett belagt system där högre hot automatiskt ger bättre loot. Beskriv inte all uppskjuten fara som samma sorts belöningsmotor. [XC-ufo], [XC-planning]
- **GISSNING – DESIGNFÖRSLAG:** Vanlig familjetrofé ska kunna fås vid trygg jakt. En framvuxen boss ger en **annan kombomöjlighet**, inte den enda hållbara healern eller en obligatorisk kampanjnyckel. Då finns ett faktiskt skäl att välja tidig jakt.
- **GISSNING – DESIGNFÖRSLAG:** Visa bossens garanterade förstabelöning innan spelaren låter sista steget ske. Återbesök ger vanlig loot; ingen oändlig extra förstabelöning.
- **GISSNING – DESIGNFÖRSLAG:** Låt upptrappningen ändra en regel, exempelvis att trollen behöver ett tydligare ljusfönster, före stora HP-påslag. Annars riskerar bättre loot betalas med längre rutinstrider.
- **GISSNING – DESIGNFÖRSLAG, testvärden:** Jämför trygg jakt med 1 vanlig belöningsenhet och mogen jakt med 2 enheter plus bossens första trofé. Om mogen jakt tar mer än dubbla tiden eller ofta misslyckas kan den ändå ge sämre resursutbyte. Mät utbyte per minut och motivationen att få den nya trofén; kalla inte den dubbla mängden automatiskt balanserad.

## L4. När blir världskartan ett arbete?

| Risk | SÄKERT – belägg eller faktiskt designingrepp | GISSNING – DESIGNFÖRSLAG | Källa |
|---|---|---|---|
| Hotet växer utan slut | Battle Brothers-utvecklaren beskrev hur tidigare kontinuerlig fraktionstillväxt kunde övermanna människovärlden; crises gav ett annat upplägg. | Sätt lokalt tak på upptrappning och pausa punkten när bossen är framme. | [BB-dev] |
| Man måste ständigt återställa samma platser | Wildermyths redesign slutade låta incursions återbesätta platser; invasionen förbrukar styrka och försvinner. | Låt en löst lokal kris verkligen vara löst en tid. | [WILD-redesign] |
| Permanent förlust stänger innehåll | Battle Brothers har valbar permanent förstörelse och fick justeringar som minskade viss förstörelseaktivitet. | Första prototypen får inte permanent radera byar eller blockerande tjänster. | [BB-crisis], [BB-patch] |
| Berättelse konkurrerar med städning | Wildermyth-kritiken beskriver tidskrav som tränger undan händelser. | Högst en ny hotförändring efter varje expedition och inga kartsteg för borgdialog. | [WILD-players] |
| Händelsen syns men förstås inte | Red Hook lade till en pulserande markering för belägringar som måste lösas. | Visa förändring, konsekvens och handlingsval tillsammans. | [DD2-fix] |
| Många upprepade försvarsstrider | Kingdoms-spelare beskriver belägringarna som grindiga. | Ett förberett lokalförsvar får klara en mindre incident utan extra strid. | [DD2-chore] |

## L5. En minsta testbar levande karta

**Allt i L5 är GISSNING – DESIGNFÖRSLAG.** Förslaget innehåller fyra kartpunkter och tre familjer. Det kräver ingen realtid, ekonomisimulering eller fritt rörliga arméer.

### Fyra fasta punkter

| Punkt | Familj och relation | Visuell förändring | Spelarens bestående framsteg |
|---|---|---|---|
| Borgen | Säker utgångspunkt | En liten rapportbild från senaste expeditionen | Alla centrala tjänster består. |
| Stenbron | Troll håller skeletten borta från vägen | Stenrösen, blockerad passage, sedan svarta märken på trollen | En räddad vakt återvänder; en tänd vårdkase består. |
| Kryptstigen | Skeletten trampar sönder spindlarnas bon | Benrester, trasiga nät, senare en synlig ledargestalt | Vägen blir ljusare efter första befrielsen. |
| Sidenlunden | Spindlarna stänger trollens genväg | Enstaka trådar, täta nät, sedan svarta märken | Bybor syns åter på den säkrade vägen. |

### Tillstånd som faktiskt behöver sparas

| Fält per farlig punkt | Tillåtna värden | Syfte |
|---|---|---|
| `growth` | 0–4 | 0: lugnt, 1: spår, 2: samlad familj, 3: tydlig varning, 4: namngiven boss. |
| `rest_runs` | 0–1 | Efter full befrielse skyddas punkten under nästa kartsteg. |
| `beacon_lit` | sant/falskt | Bestående visuell framgång. |
| `boss_reward_claimed` | sant/falskt | Unik förstabelöning får bara delas ut en gång. |

Familj, relation, boss och bildpaket är fasta data. Globalt behövs ett expeditions-ID och en enkel växlingspekare. `growth` är ett internt tal; spelaren ser stadierna, inte procent.

### Exakt uppdateringsordning

1. **Ett kartsteg per expedition med minst en avslutad strid.** Återvända före första striden ger inget steg. Borgbesök, menyer och verkliga dygn gör ingenting. Död efter en strid räknas också som expedition; detta måste framgå första gången.
2. Spara vilka punkter som hade `rest_runs=1` före uppdateringen. De får ingen tillväxt detta steg; deras skydd räknas sedan ned.
3. Om områdets huvudmål klarades: sänk den angripna punktens `growth` med 2, lägst 0. Vid 0 tänds vårdkasen om det är första befrielsen och `rest_runs` sätts till 1 för nästa steg. En besegrad boss återställer sin punkt direkt till 0.
4. Öka **högst en annan punkt** med 1. Prioritera den familj som den besegrade familjen höll tillbaka: troll besegrade → skelett får spelrum; skelett besegrade → spindlar får spelrum; spindlar besegrade → troll får spelrum. Om ingen huvudseger inträffade väljs en tillåten annan punkt med växlingspekaren.
5. En skyddad punkt och punkter på 4 kan inte väljas. Om prioriterad punkt inte kan växa väljs nästa tillåtna punkt i fast växlingsordning. Finns ingen tillåten punkt sker ingen tillväxt.
6. Vid övergång 3 → 4 skapas bossen. Därefter står punkten stilla tills spelaren ingriper; den invaderar inte fler platser i prototypen. Varning på 3 säger uttryckligen att nästa tillväxt kan skapa bossen.
7. Visa en kort före/efter-bild med en orsaksrad. Alla effekter bokförs mot expeditions-ID så att återladdning inte dubblar steget.

Detta är en avsiktlig förenkling: ”en plats växer efter er expedition”, inte ”alla obevakade familjer växer varje gång”. Den testar grundkänslan utan att skapa tre samtidiga underhållskrav.

### Ett konkret förlopp

| Händelse | Bron: troll | Kryptstigen: skelett | Lunden: spindlar | Vad spelaren förstår |
|---|---:|---:|---:|---|
| Start | 2 | 1 | 1 | Trollgruppen är tydligast samlad. |
| Seger vid bron | 0 | 2 | 1 | Bron lugnas; skeletten får mer spelrum. |
| Seger vid kryptstigen | 0 | 0 | 2 | Bron skyddas detta steg; spindlar växer efter skelettens nederlag. |
| Ännu en expedition mot trollen, huvudseger | 0 | 0 | 3 | Kryptstigen är skyddad detta steg; i stället växer lunden till sitt varningsstadium. |

Vid varje huvudseger prioriteras relationen enligt uppdateringsregeln. Tabellen är ett räkneexempel, inte ett utfall från ett genomfört speltest.

### Så testar ni ”känns det levande?”

- Kör först 6–8 expeditioner med några få testare. Fråga efter återkomst: ”Vad ändrades?”, ”Varför?”, ”Vad tror du händer om du går någon annanstans?” Det är ett kvalitativt prototyptest, inte en statistisk validering.
- Anteckna om de väljer plats av nyfikenhet, troféjakt, familjekombo eller känsla av tvång. Tre personer som beskriver kartan som städning är en varningssignal även om de klarar den.
- Testa både en spelare som jagar bossen och en som gör trygga troféjakter. Båda ska kunna fortsätta bygga sitt lag.
- Låt första testet behålla tända vårdkasar och återvända bybor även när ett nytt lokalt hot uppstår. Befrielse ska lämna ett synligt spår.

---

# M. Utforskning utan slentrian

## M1. Hur gör rut- och dimspel utforskning till beslut?

| Spel | SÄKERT – faktisk mekanik | TROLIGT – vad som skapar ett beslut | Källa |
|---|---|---|---|
| Dungelot: Shattered Lands | Ett våningsplan har 25 rutor. En dold nyckel öppnar utgången; levande monster blockerar närliggande rutor. Begränsad återhämtning gör onödiga strider kostsamma. | Nyckeln tillåter avfärd, medan blockerare gör vissa fynd dyra att nå. Det betyder inte att varje okänd ruta har ett välunderbyggt vägval. | [DUNG-review], [DUNG-decisions] |
| Desktop Dungeons | Nyavslöjad ruta ger normalt 1 mana och HP lika med egen level. Skadade monster återfår också HP lika med sin level per ruta. | Dimman är sparad återhämtning. Fullsvep före strid förbrukar något man kan behöva senare. | [DESK-guide] |
| Dungeon of the Endless | Dörröppning producerar resurser och kan skapa vågor från mörka obemannade rum. 10 Dust räcker för att strömförsörja ett rum. | Varje öppning kan ge både avkastning och ett växande försvarsproblem. Tidpunkten och basens beredskap spelar roll. | [END-guide], [END-devforum] |
| Card Hunter | Stridens beslut styrs av kort, förflyttning, line of sight och terräng. Victory Squares kan ge segerpoäng. | Relevant för taktisk placering och mål, men ett svagt exempel på fri dimutforskning. Kopiera inte dess stridsruta som om den löste er sökruta. | [CARD-rules] |
| Loop Hero | Spelaren placerar landskap och hot längs en automatisk väg; fler varv ökar fiende- och utrustningsnivåer. Retur vid camp skyddar resurser. | Spelaren skapar sin framtida risk och väljer när resan ska sluta. Det är inte manuell fog-sökning. | [LOOP-camp], [LOOP-placement], [LOOP-retreat] |
| Darkest Dungeon 1 | Torchlight påverkar bland annat scouting och risk. Radiant light över 75 ger +15 procentenheter scouting jämfört med mörker. | Vägval kan grundas på förhandsinformation; resurser gör även en känd omväg meningsfull. | [DD-scout], [DD-light] |
| Siralim Ultimate | Realms är slumpgenererade, med Realm Quests och flera typer av sidoobjekt. Treasure Maps sätter ett synligt kryss på kartan. | En del sökande får riktning. Men många belöningar utan förbrukningskostnad kan fortfarande uppmuntra fullsvep. | [SU-realms] |
| Pathfinder 2e Hexploration | Travel och Reconnoiter är skilda aktiviteter, ofta 1 aktivitet vardera i öppen terräng. En hex är cirka 12 miles tvärs över. | Att passera och att undersöka behöver inte vara samma beslut. Går att överföra som snabb passage kontra medvetet sökande. | [PF-hex] |
| DemonCrawl | Minesweeper-ledtrådar låter spelaren härleda säkra rutor. HP-systemet gör att ett misstag inte alltid avslutar spelet. | Information gör okända rutor olika intressanta; utan ledtrådar är öppnandet bara en lottdragning. | [DEMON-faq], [DEMON-guide] |
| Hoplite | Små hexbanor med utgång, fiender och uppgraderingsaltare. Det går att prioritera altaret eller snabb väg till trappan. | Belöningen och dess läge är begripliga före omvägen. Inte samma utforskningsmodell som en dold 8×8-karta. | [HOP-review] |

- **TROLIGT:** De starkaste överförbara mönstren är **information före åtagande**, **en begränsad resurs som kan användas på olika sätt** och **en tydlig möjlighet att lämna**. Större slumpkarta i sig tillför inget av dessa. [DESK-guide], [END-guide], [PF-hex], [HOP-review]

## M2. Vad säger Siralim-spelarna, och vad förbättrades?

- **SÄKERT – spelaråsikt:** En Realm Traversal-tråd beskriver gång genom procedurgenererade korridorer som tråkigare och mer tidskrävande än striderna; andra deltagare pekar på inställningar och uppskattar den övriga Realm-loopen. Det belägger en konflikt mellan spelarpreferenser, inte att utforskningen generellt är misslyckad. [SU-walking]
- **SÄKERT – spelaråsikt:** App Store-omdömen innehåller uttryckligt beröm för avslappnande dungeon crawling. Det är ett annat slags värde än svåra vägval. [SU-appreviews]
- **SÄKERT – spelaråsikter:** Diskussionen om att rensa allt eller snabbt avsluta Realm Quest har både samlarorienterade och snabbprogressionsorienterade svar. **TROLIGT:** ”optimal utforskning” varierar med mål som achievements, farming och djup. [SU-sweep]
- **SÄKERT:** Double Movement Speed fanns redan långt före 2.0; tidiga patch notes nämner inställningen. Påstå inte att den introducerades med 2.0. [SU-oldpatch]
- **SÄKERT – 2.0:** Utvecklaren förbättrade Fog of War, Realm-generation, Ultra turbo och information om hittade Project items. False God-portalen ändrades till att kräva alla 5 runor i stället för alla besegrade fiender. Det sistnämnda tar bort ett specifikt rensningskrav. [SU-patch]
- **SÄKERT:** Divination Candle ger riktad möjlighet att kalla fram sökta varelser. Grundkostnaden börjar på 1 000 Power och ökar med 1 000 per användning i samma Realm enligt wikin. Det minskar viss sökslump, men avskaffar inte gångsträckor. [SU-candle]
- **Vet inte:** Jag har inte belagt en allmän auto-explore-funktion som löser Siralim Ultimate 2.0:s karttraversering. Auto-loot, snabbare gång och snabbare strider är olika funktioner.
- **TROLIGT:** Att snabba upp transport minskar friktion. För att skapa fler verkliga utforskningsbeslut måste också informations- och belöningsstrukturen förändras. [SU-walking], [DESK-guide], [HOP-review]

## M3. Mekaniker mot fullsvep – vad talar för och emot dem?

| Mekanik | SÄKERT – förebild | TROLIGT – när den hjälper | GISSNING – risk i ert spel | Källa |
|---|---|---|---|---|
| Ledtrådar i dimman | Minesweeper/DemonCrawl ger användbar närhetsinformation. | När två riktningar har olika förväntat innehåll. | Otydliga dekorationer blir falska löften. Säg ”skatt i denna del”, inte ett dekorativt glitter utan regel. | [DEMON-guide] |
| Avslöjad intressant omväg | Hoplites altare och trappa ger olika mål. | När spelaren känner belöning och kostnad före avsteget. | Fynd som alltid är gratis att hämta blir fortfarande obligatoriska. | [HOP-review] |
| Bevara outforskade rutor | Desktop Dungeons gör varje ruta till återhämtning. | När samma resurs behövs vid flera tidpunkter. | Er HP/Charges-ekonomi är inte Desktop Dungeons. Att automatiskt fylla Charges här kan urholka körningsresursen. | [DESK-guide] |
| Öppning ökar hot | Dungeon of the Endless kopplar dörrar till vågor och produktion. | När spelaren styr när nästa öppning sker och kan förbereda sig. | En skatt på varje steg kan göra själva upptäckandet till ett straff. | [END-guide] |
| Ljus eller förråd | Darkest Dungeon kopplar ljus till risk, förutsägbarhet och loot. | När spelaren kan köpa, spara, återställa och medvetet avstå resursen. | En osynlig timer tillsammans med dolda questföremål blir orättvis sökpress. | [DD-light] |
| Trygg avfärd | Loop Hero skiljer resursbevarande vid camp från riskfylld fortsättning. | När ett avslut är ett godtagbart utfall med redan säkrad belöning. | En stor speedbonus kan göra långsam eftertanke till ekonomiskt fel spelstil. | [LOOP-retreat] |

- **GISSNING – DESIGNFÖRSLAG:** Börja med bättre information och en nåbar huvudväg. Lägg till resurskostnad för **frivillig riskhandling**, exempelvis att bryta upp en bevakad skattkammare, före en kostnad för varje vanligt fotsteg.
- **GISSNING – DESIGNFÖRSLAG:** När huvudmålet är klart säger Gorm: ”Uppdraget är färdigt. Resten väljer du själv.” Utgången blir då tydlig. Visa kända kvarvarande möjligheter som ”lägereld” och ”elit”, utan löfte om dolda fynd på varje tom ruta.
- **GISSNING – DESIGNFÖRSLAG:** Ge ingen extra belöning för 100 % avslöjad karta och placera inte ett osignalerat obligatoriskt föremål på sista slumpmässiga rutan. Båda reglerna lär annars ut fullsvep oavsett hur bra övriga val är.

## M4. Täthet: är 6×6 bättre än 8×8?

### Vad går faktiskt att räkna?

- **SÄKERT – BERÄKNING:** 8×8 har 64 rutor; 6×6 har 36. Det är **28 färre rutor**, eller **43,75 % mindre yta**. Det innebär inte automatiskt 43,75 % kortare speltid: strider, väggar, omvägar och återbesök påverkar. Källa: aritmetik från uppdragets mått.
- **SÄKERT – BERÄKNING, exempel:** Med 5 vanliga strider + 1 elit + 2 skatter + 1 shrine + 1 lägereld + 1 questföremål + 1 utgång finns 12 innehållsrutor. Bruttotätheten blir **18,75 %** på 8×8 och **33,33 %** på 6×6. Med 6 vanliga strider blir det 13 rutor: cirka 20,31 % respektive 36,11 %. Antalet skatter/lägereldar här är ett räkneantagande, inte ert bekräftade innehåll.
- **SÄKERT – BERÄKNING, förenklad sökmodell:** Om ett obligatoriskt föremål är jämnt slumpat bland N rutor och spelaren inte har ledtrådar, hittas det i genomsnitt efter (N+1)/2 unika avslöjanden: **32,5** på 64 rutor och **18,5** på 36. Det mäter avslöjanden, inte gångsteg.
- **SÄKERT – BERÄKNING, samma modell:** Krävs alla m slumpade föremål är den förväntade sista fyndpositionen m(N+1)/(m+1). Med tre föremål bland 64 rutor blir det **48,75 avslöjanden**, cirka 76 % av rutorna. Även rationellt målinriktade spelare kan alltså drivas nära fullsvep av själva uppdragsregeln.
- **Vet inte:** Jag har inte hittat en jämförbar, uppmätt branschnorm för ”meningsfulla händelser per steg” i de namngivna spelen. Dungelots 25 rutor, Desktop Dungeons blackspace och Hoplites öppna strid kan inte göras till samma täthetsmått utan stora antaganden. [DUNG-review], [DESK-guide], [HOP-review]

### Rekommenderat test

- **GISSNING – DESIGNFÖRSLAG:** A/B-testa 8×8 och 6×6 med samma kärninnehåll och jämförbar väggstruktur. 6×6 är en rimlig kandidat för mindre tom transport; den är inte en lösning på obligatoriskt fullsvep.
- **GISSNING – DESIGNFÖRSLAG:** Mät medianen för nya rutor mellan två relevanta fynd, steg på redan besökta rutor, tid från klart uppdrag till avfärd och andel runs där spelaren medvetet lämnar kvar innehåll. Enbart ”kortare run” visar inte att besluten blev bättre.
- **GISSNING – DESIGNFÖRSLAG:** Märk också **beslut** separat från händelser. En gratis kista är en belöning; ”kista bakom elit eller trygg lägereld” är ett val. Prova att skapa 2–3 sådana tydliga situationer per våning innan ni höjer total mängd innehåll.
- **GISSNING – DESIGNFÖRSLAG:** Genereringen måste garantera nåbart huvudmål, utgång och minst en användbar väg. Särskilt en tät 6×6-karta kan annars bli mer blockerad och mindre valbar. QCF beskrev att okontrollerad monsterplacering i Desktop Dungeons kunde ge extrema eller omöjliga starter. [DESK-generation]

## M5. Åtta förändringar, rangordnade efter förväntad nytta mot kostnad

**Hela rankningen är GISSNING – DESIGNFÖRSLAG.** Kostnaderna är relativa bedömningar eftersom er kodbas inte har granskats. Ingen procentuell effekt på retention påstås.

| Rang | Förändring | Förväntad effekt | Relativ kostnad | Risk och hur den hålls nere | Inspiration |
|---:|---|---|---|---|---|
| 1 | **Ge obligatoriska fynd en riktning.** Vid entrén visas en sann ledtråd om vilket område questmålet finns i; följ upp nära målet. | Minskar rationellt söktvång och gör vägval möjliga. | Låg–medel | För exakt pil kan ta bort upptäckt. Visa region/tecken före exakt ruta. | [SU-realms], [PF-hex] |
| 2 | **Öppna en tydlig avfärd när huvudmålet är klart.** Ingen full-clear-bonus; utgången markeras och dess väg ska vara nåbar. | Gör ”nu räcker det” till ett legitimt val. | Låg–medel | Spelaren kan springa förbi allt. Behåll synliga attraktiva sidomål. | [DUNG-decisions], [LOOP-retreat] |
| 3 | **Testa 6×6 med samma kärninnehåll.** | Minskar tomrutor och transport; enklast att isolera som karttest. | Låg om generatorn är parametrisk, annars medel | Tätare monster kan strypa vägar. Validera nåbarhet och alternativ. | [DUNG-review], [DESK-generation] |
| 4 | **Visa en lockelse genom dimman.** Till exempel skattkammarens dörr eller lägereldens sken, med en tillförlitlig förklaring. | Gör okända riktningar olika värdefulla utan att avslöja allt. | Medel | Dekoration som misstolkas. Använd få konsekventa signaler. | [HOP-review], [DEMON-guide] |
| 5 | **Placera två behov som konkurrerar.** Exempel: kort väg via en hård strid eller omväg till lägereld innan eliten. | Skapar val kopplade till lagets aktuella skick. | Medel | Ett alternativ blir alltid bäst. Kontrollera att olika lag/skadelägen faktiskt väljer olika. | [DESK-guide], [DD-light] |
| 6 | **Snabbförflyttning på säkra besökta rutor.** Tryck på känd målpunkt; stopp vid ny händelse eller förändrat hot. | Tar bort repetitiva återtryckningar. Skapar främst mindre friktion, inte nya strategiska beslut. | Medel | Kan passera ett nytt hot. Begränsa till känd säker väg och avbryt vid ändring. | [SU-walking] |
| 7 | **Sökhandling som kostar en konkret möjlighet.** Vid shrine väljer spelaren antingen spaning över en del av dimman eller dess andra vanliga belöning. | Information får värde; även ett starkt lag kan välja bättre sökunderlag. | Medel | Spanning blir obligatorisk skatt. Justera kartans grundinformation först. | [PF-hex], [DD-scout] |
| 8 | **Frivilligt hotsteg vid särskilt giriga handlingar.** Öppna förseglad extra skatt → en annonserad förstärkning eller svårare nästa möte. | Ger push-your-luck på en avgränsad plats. | Medel–hög | Skapar mer strid och kan straffa nyfikenhet. Använd i högst en tydlig situation per våning i första testet. | [END-guide], [LOOP-placement] |

### Vad jag skulle testa först

- **GISSNING – DESIGNFÖRSLAG:** Första versionen: rang 1 och 2 på nuvarande karta. Andra jämförelsen: samma regler på 6×6. Då kan ni skilja effekten av bättre målstruktur från effekten av mindre yta.
- **GISSNING – DESIGNFÖRSLAG:** Lägg därefter till en enda synlig frivillig omväg och se om spelaren väljer olika beroende på lagets skick. Vänta med generell mat-/ljusförbrukning tills det finns belägg för att information och målstruktur inte räcker.

---

## Källregister

Referenserna nedan används som klickbara källor i texten. Nuvarande wikiuppgifter är inte historiska changelogs; utvecklarens patch notes har företräde vid belagd versionsändring. Spelartrådar används som exempel på upplevelser, inte som populationsdata.

[SU-debuffs]: https://siralimultimate.wiki.gg/wiki/Debuffs
[SU-statusguide]: https://steamcommunity.com/sharedfiles/filedetails/?id=3784387412
[SU-blind]: https://siralimultimate.wiki.gg/wiki/Debuff
[SU-scorned]: https://siralimultimate.wiki.gg/wiki/Debuffs
[SU-buffs]: https://siralim-ultimate.fandom.com/wiki/Status_Effects
[SU-status]: https://siralimultimate.wiki.gg/wiki/Status_Effects
[SU-arach]: https://siralimultimate.wiki.gg/wiki/Arachnalisk
[SU-dragonlair]: https://siralimultimate.wiki.gg/wiki/Dragonlair_Arachnalisk
[SU-ancientarach]: https://siralimultimate.wiki.gg/wiki/Ancient_Arachnalisk
[SU-razorweb]: https://siralimultimate.wiki.gg/wiki/Razorweb_Arachnalisk
[SU-woolly]: https://siralimultimate.wiki.gg/wiki/Woolly_Arachnalisk
[SU-hotfix]: https://steamcommunity.com/app/1289810/discussions/0/598541643424086679/
[SU-sorcerer]: https://siralimultimate.wiki.gg/wiki/Sorcerer
[SU-yetisigil]: https://siralimultimate.wiki.gg/wiki/Sigil_of_the_Yeti
[SU-siren]: https://siralimultimate.wiki.gg/wiki/Siren
[SU-marionette]: https://siralimultimate.wiki.gg/wiki/Marionette_Hypnotist
[SU-satyr]: https://siralimultimate.wiki.gg/wiki/Satyr
[SU-toxicbuild]: https://www.reddit.com/r/Siralim/comments/wr83rs/
[SU-deepfreeze]: https://siralimultimate.wiki.gg/wiki/Deep_Freeze
[SU-freezebuild]: https://www.reddit.com/r/Siralim/comments/xcv3gn/
[SU-defiler]: https://siralimultimate.wiki.gg/wiki/Defiler
[SU-defilerplayers]: https://www.reddit.com/r/Siralim/comments/zfcbvg/
[SU-patch]: https://www.thylacinestudios.com/blog/siralim-ultimate-2-0-patch-notes
[SU-mesmerist]: https://siralimultimate.wiki.gg/wiki/Mesmerist
[SU-mesmeristpreview]: https://steamcommunity.com/app/1289810/discussions/0/598518216964247188/
[DD-stun]: https://darkestdungeon.wiki.gg/wiki/Stun_%28Darkest_Dungeon%29
[STS-debuffs]: https://slaythespire.wiki.gg/wiki/Debuffs
[STS-artifact]: https://slay-the-spire.fandom.com/wiki/Artifact
[ITB-status]: https://intothebreach.fandom.com/wiki/Abilities_and_status_effects
[ITB-guide]: https://intothebreach.fandom.com/wiki/How_To_Play_Guide_For_Into_The_Breach
[PK-sleep]: https://bulbapedia.bulbagarden.net/wiki/Sleep_%28status_condition%29
[PK-paralysis]: https://bulbapedia.bulbagarden.net/wiki/Paralysis
[PK-freeze]: https://bulbapedia.bulbagarden.net/wiki/Freeze_%28status_condition%29
[OT-break]: https://gamefaqs.gamespot.com/switch/204212-octopath-traveler/answers/495528-how-does-breaking-enemies-work
[OT-system]: https://www.gamerguides.com/octopath-traveler/guide/introduction/game-mechanics/battle-system
[WF-dev]: https://chucklefish.org/blog/wildfrost-dev-update-2023-release-with-cool-new-features/
[WF-resist]: https://wildfrostwiki.com/Resist_Snow
[WF-snow]: https://wildfrostwiki.com/Snow
[SU-ent]: https://siralimultimate.wiki.gg/wiki/Ent
[SU-blight]: https://siralimultimate.wiki.gg/wiki/Debuffs
[STS-mystic]: https://slaythespire.wiki.gg/wiki/Centurion_and_Mystic
[DD-shaman]: https://darkestdungeon.wiki.gg/wiki/Pelagic_Shaman
[ITB-blood]: https://intothebreach.fandom.com/wiki/Blood_Psion
[FF-yunalesca]: https://finalfantasy.fandom.com/wiki/Yunalesca_%28boss%29
[MT-trials]: https://www.neoseeker.com/monster-train/walkthrough/Trials_and_Boss_Effects
[MT-detonation]: https://monster-train.fandom.com/wiki/Restoration_Detonation
[MT-players]: https://www.reddit.com/r/MonsterTrain/comments/gwl0d1/
[SU-nephilim]: https://siralimultimate.wiki.gg/wiki/Nephilim_Cleric
[SU-caritas]: https://siralimultimate.wiki.gg/wiki/Caritas_Sanctus
[SU-clairvoyant]: https://siralimultimate.wiki.gg/wiki/Clairvoyant_Spirit
[SU-succubus]: https://siralimultimate.wiki.gg/wiki/Succubus_Spirit
[SU-cleric]: https://siralimultimate.wiki.gg/wiki/Cleric
[SU-clericguide]: https://steamcommunity.com/sharedfiles/filedetails/?id=2811963801
[SU-combat]: https://siralimultimate.wiki.gg/wiki/Combat
[SU-faq]: https://siralimultimate.wiki.gg/wiki/Frequently_asked_questions
[SU-healloop]: https://www.reddit.com/r/Siralim/comments/1kamc3s/
[SU-loopdiscussion]: https://www.reddit.com/r/Siralim/comments/1fomio0/
[XC-avatar]: https://xcom.fandom.com/wiki/Avatar_Project
[XC-ufo]: https://www.ufopaedia.org/index.php/Avatar_Project_%28XCOM2%29
[XC-players]: https://steamcommunity.com/app/268500/discussions/0/358415738197045199/
[XC-planning]: https://www.reddit.com/r/XCOM2/comments/uc4qjk/
[NEM-manual]: https://www.feralinteractive.com/en/manuals/shadowofmordor/latest/steam/
[NEM-tips]: https://www.gamespot.com/gallery/shadow-of-war-guide-11-tips-we-wish-we-knew-before/2900-1539/
[NEM-threat]: https://vulkk.com/2017/09/16/death-threat-works-shadow-war/
[NEM-gear]: https://wbgamessupport.wbgames.com/hc/en-us/articles/360001100088-Gear-FAQ
[NEM-players]: https://www.reddit.com/r/shadowofmordor/comments/wpbaum/
[BB-dev]: https://battlebrothersgame.com/dev-blog-92-late-game-crises/
[BB-crisis]: https://battlebrothers.fandom.com/wiki/Late_Game_Crises
[BB-players]: https://battlebrothersgame.com/forums/topic/where-did-the-no-crisis-button-go/
[BB-patch]: https://battlebrothers.fandom.com/wiki/Update_1.2.0.17
[DD-events]: https://darkestdungeon.wiki.gg/wiki/Town_Events
[DD-courtyard]: https://darkestdungeon.wiki.gg/wiki/Infestation
[DD2-flame]: https://darkestdungeon.wiki.gg/wiki/Infernal_Flame
[DD2-loathing]: https://darkestdungeon.wiki.gg/wiki/Loathing
[DD2-kingdoms]: https://darkestdungeon.wiki.gg/wiki/Kingdoms
[DD2-review]: https://digitalchumps.com/darkest-dungeon-ii-kingdoms-dlc-review/
[DD2-positive]: https://www.reddit.com/r/darkestdungeon/comments/1idyuwu/
[DD2-chore]: https://www.reddit.com/r/darkestdungeon/comments/1ihbw8y/
[DD2-fix]: https://www.darkestdungeon.com/news/steadfast-steward-s-update-3rd-build-live-/
[MB-villages]: https://mountandblade.fandom.com/wiki/Villages
[MB-dev]: https://store.steampowered.com/news/posts/?appids=261550&enddate=1558643307
[WILD-infest]: https://wildermyth.com/wiki/Infestation
[WILD-redesign]: https://wildermyth.itch.io/wildermyth/devlog/225984/patch-notes-034253-elsee-arcwright
[WILD-timers]: https://wildermyth.itch.io/wildermyth/devlog/91147/patch-notes-0559-garnoc-ambertoe
[WILD-players]: https://steamcommunity.com/app/763890/discussions/1/3053985636038694275/
[ITB-islands]: https://intothebreach.fandom.com/wiki/Islands
[HADES-dev]: https://www.supergiantgames.com/blog/hades-updates/
[HADES-dialogue]: https://www.christi-kerr.com/post/how-the-dialogue-system-in-hades-rewards-failure
[INS-reset]: https://steamcommunity.com/app/1092790/discussions/0/516333215744562519/
[INS-deathcard]: https://inscryption.fandom.com/wiki/Deathcard
[DOM-manual]: https://www.illwinter.com/dom6/dom6manual.pdf
[FH-save]: https://fearandhunger.wiki.gg/wiki/Saving
[FH-characters]: https://fearandhunger.wiki.gg/wiki/Termina_Characters
[LOOP-camp]: https://loophero.fandom.com/wiki/Campfire_%28tile%29
[LOOP-retreat]: https://twinfinite.net/guides/loop-hero-return-to-camp-how/
[LOOP-placement]: https://www.pcgamesn.com/loop-hero/beginners-guide-tips-tricks
[DUNG-review]: https://worthplaying.com/article/2016/4/22/reviews/99220-pc-review-dungelot-shattered-lands/
[DUNG-decisions]: https://www.analogaddiction.org/2016/03/01/dungelot-shattered-lands-review
[DESK-guide]: https://www.qcfdesign.com/wiki/DesktopDungeons/index.php?title=New_Players_Guide
[DESK-generation]: https://www.qcfdesign.com/?m=201306
[END-guide]: https://steamcommunity.com/sharedfiles/filedetails/?id=203411482
[END-devforum]: https://community.amplitude-studios.com/amplitude-studios/dungeon-of-the-endless/forums/53-faq/threads/17878-things-every-new-player-needs-to-know
[CARD-rules]: https://www.cardhunter.com/how-to-play-card-hunter/
[DD-scout]: https://darkestdungeon.wiki.gg/wiki/Scouting
[DD-light]: https://darkestdungeon.wiki.gg/wiki/Light_meter
[SU-realms]: https://siralimultimate.wiki.gg/wiki/Realms
[PF-hex]: https://2e.aonprd.com/Rules.aspx?ID=3103
[DEMON-faq]: https://demoncrawl.com/faq/
[DEMON-guide]: https://steamcommunity.com/sharedfiles/filedetails/?id=1917065069
[HOP-review]: https://games.jayisgames.com/review/hoplite.php
[SU-walking]: https://www.reddit.com/r/Siralim/comments/1t6zuuf/tedious_realm_traversal/
[SU-appreviews]: https://apps.apple.com/us/app/siralim-ultimate/id1601114348?platform=iphone&see-all=reviews
[SU-sweep]: https://www.reddit.com/r/Siralim/comments/1jjau4w/
[SU-oldpatch]: https://steamdb.info/patchnotes/5497164/
[SU-candle]: https://siralimultimate.wiki.gg/wiki/Divination_Candle
