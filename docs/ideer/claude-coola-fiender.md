# Coola fiender – idétrådens förslag (2026-10-23)

Underlag, inget beslutat; VD bestämmer. Läst: CLAUDE.md, `docs/plan/roligare-fiender.md` (granskningen upprepas inte),
`chat-familjer-karta-grottan.md` §K, `docs/plan/levande-karta.md`, `chat-realm3-kallornas-tradgard.md`,
`docs/research/siralim.md` §4 och §7. Spindlarna byggs i en annan tråd (Lunden) och berörs inte.
Märkning som i 0.27-planen: **Siralim** = förebild i originalet, **VAL** = vårt, ⚙ = ny kod (S liten, M mellan).

**Måttstocken** (granskningens): en fiende är rolig när den ställer en fråga som en trofé eller en makrorad kan svara på.
**Tillägget här:** fienden ska också vara rolig att *bära*, alltså vända sin egen regel åt spelarens håll, helst så att den
gör en annan fiende eller en annan hjälte bättre. **Motvikten:** i dag säger åtta egenskaper "anfall inte" och två "kasta
inte". Nedan märks varje fiende med vad den straffar: **[F]** förmåga, **[H]** helning, **[B]** buff, **[P]** Provocera,
**[V]** Försvara, **[A]** anfall. Målet är att ingen av dem ska vara ett universalsvar.

**Avsikten måste synas.** Många av förslagen bygger på klockor ("var tredje tur") och reaktioner. Det förutsätter två
saker granskningen redan föreslog: nedräkningen syns i avsikten, och makrovillkoret **"en fiende siktar på mig"** (⚙S).
Ett tredje villkor behövs för några: **"fiendens avsikt är X"** (sång, order, blixt; ⚙S, samma data som avsiktsikonen).

## 1. Trollfamiljen: Trollfolket (`troll_kin`)

Ton: stora, sura, lata och lite rörande; de bor under broar och i mossiga backar och har blivit lovade "evig mättnad" av
någon med en krona med tom mitt. Artregel (research K, **VAL**): **trollens egna helningar uteblir till deras nästa tur
efter att de tagit skada av en förmåga** (står i Inspect som "Trollhud: förmågor stoppar läkningen"). Familjens
grundfråga blir: *när* slår du med förmåga, och hinner du före läkningen? Artregeln följer inte med trofén.

| Fiende | Roll | Egenskapen (Inspect) | Frågan och makroraden | Trofén åt spelaren | Modell |
|---|---|---|---|---|---|
| **Mossrygg** | vanlig | *Mossa:* helas 10 % av max liv i början av sin tur. | Hinner ni före mossan? Rad: "om fiende har Mossa → förmåga mot den" (artregeln). Ett vänligt första troll. [A] | *Mossa:* bäraren helas 6 % i början av sin tur. Pålitlig byggdel, gör Brokk till en vägg. | Trollet (Blender, se nedan), grön mossa på ryggen. |
| **Gröt-Gudrun** | vanlig | *Sju sorters gröt:* varje gång en hjälte helas blir Gudrun mättare: +20 % på nästa anfall (högst 3, syns som skålar). | Hela mindre och smartare, eller döda henne först. Rad: "om fiende har Sju sorters gröt → hela bara under 35 %". **[H]** Siralim: Dragon Queen-mönstret. | *Grötskål:* när en fiende helas får bäraren +20 % på nästa anfall (högst 3). Svaret på Kultisten, diakonen och Abbedissan. | Trollet, förkläde (stel del) och slev i `grip_r`. |
| **Grinig-Gunnar** | vanlig | *Avund:* när en hjälte får en buff får Gunnar samma buff. | Buffa inte i onödan, eller rensa honom. Rad: "om fiende har Avund och har buff → rensa / anfall den". **[B]** Siralim: kopierande traits (Mimic-mönstret). | *Avund:* när en fiende får en buff får bäraren samma (en gång per tur). Mot Fanbäraren, Abbedissan, Asketens försvar. Kombinerar med Immas Fingerfärdig. | Trollet, armarna i kors (baspose), mörkare tint. |
| **Klubb-Kalle** | vanlig | *Klubban:* anfall mot en hjälte som Försvarar gör dubbel skada och bryter försvaret. | Försvara inte när Kalle siktar på dig – slå i stället. Rad: "om en fiende med Klubban siktar på mig → anfall" (⚙S villkoret). **[V]** | *Klubban:* bärarens anfall mot en fiende som Försvarar eller är Defensiv gör +50 % och tar bort Defensiv. Svaret på Fallen riddare och Skramlaren. | Trollet med Maul ur `vapen.glb`. |
| **Brom, broarnas väktare** | miniboss | *Tull:* bryr sig inte om Provocera; anfaller den som skadade honom senast, +50 % mot den som Provocerat. | Vem vågar slå sist? Låt tanken ge sista slaget eller släpp Provocera. Rad: "om fiende har Tull → Försvara i stället för Provocera". **[P]** | *Tull:* bärarens anfall mot den fiende som senast skadade bäraren gör +30 %. Hämnarens trofé; en motor för Paladinens Domens kall. | Trollet ×1,3, brospänne (bälte) och lykta. |
| **Trollmor Gråluva** | elit | *Vaggvisa:* var tredje tur sjunger hon; varje hjälte som använt en förmåga sedan förra sången Sover 1 tur (nedräkningen syns). | Kasta före sången, inte efter; anfall eller Försvara när den är nära. Rad: "om fiendens avsikt är Vaggvisa → anfall" (⚙S). **[F]** | *Vaggvisa:* var tredje tur somnar fienden som senast kastade en förmåga. Elit = specialiserad: kväser Häxan och Gravdimman. | Trollet, sjal (stel del), stickor. Mjuk sång som ljudcue. |
| **Bergakungen Grumse** | boss | *Stenhjärta:* om en hjälte gör samma sorts handling som hjälten före (anfall efter anfall, förmåga efter förmåga) blir Grumse sten: −60 % skada tills någon gör något annat. Under 50 %: *Gryningen* – han blir Förstenad 1 tur var fjärde tur (fönster). | Variera i sällskapet: makrona får inte alla säga samma sak. Ett lagpussel, inte ett hjältepussel. **[A]+[F]** (båda). | *Stenhjärta* (regel med kostnad): bäraren tar −60 % från samma sorts fiendehandling två gånger i rad, **men** kan inte göra samma handling två egna turer i rad. | Trollet ×1,6, stenkrona med tom mitt (tråden från kapellet). |

**Kedjor att vilja testa:** Mossa + Grötskål på samma Brokk (han äter sig stark när kulten helar sig). Avund på Imma
(hon stjäl en buff och kopierar fiendens nästa). Klubban + Tull på Paladinen (hämnd mot vakter).
**Gruppmallar (en fråga var):** "Söndagsgröt" (Gudrun + Mossrygg: hela inte i onödan), "Bron" (Brom + 2 Mossryggar:
vem slår sist), "Barnkammaren" (Gråluva elit + Gunnar: kasta i rätt fönster).

**Modellen** (Blender-tråden, som jättespindeln): en lågpolyfigur av stela delar: rundad bål framåtlutad, litet huvud
med stor näsa, långa armar med knytnävar som når knäna, korta tjocka ben, mosstofsar och en svans med tofs. Skelett med
~14 ben (Hips, Spine, Chest, Head, Jaw, Shoulder/UpperArm/LowerArm/Hand ×2, UpperLeg/LowerLeg ×2, Tail) och `grip_r`, så
att `vapen.glb` hänger i handen. Animationer i `procedural_anims.gd`: Idle (gungande), Attack (tvåhandsslag), Hit,
Death (sätter sig tungt), Cast (klappar magen). En kropp, sex trollar med tint, tillbehör och skala. Nödlösning till dess:
`brokk.glb` ×1,5 med grå-grön tint (osäkert hur det ser ut; dvärgen är för kompakt).

## 2. Två nya familjer i korthet

### 2a. Mässingsverket (`brass_kin`) – det kuvade solverket (ChatGPT:s koncept 4)
Dvärgbyggda automater som ledde dagsljus ned i gruvorna; en "rådgivare" ställde om dem till att *vakta* ljuset i stället.
Familjens fråga: **förmågor och buffar kostar** – verket räknar och svarar. Brokk har något att säga om hantverket.

| Fiende | Roll | Egenskapen | Fråga / rad | Trofén | Modell |
|---|---|---|---|---|---|
| **Kuggknekten** | vanlig | *Räkneverk:* efter var tredje hjälteförmåga gör den ett extra anfall (räknaren syns). | Döda den eller blanda in anfall. Rad: "om fiende har Räkneverk → anfall". **[F]** | Efter var tredje allierad förmåga gör bäraren ett extra anfall. Gör Alva och Ragnhild till anfallsmotorer. | `rustning.glb`, mässingstint, glow i hjälmen. |
| **Spegelputsaren** | vanlig | *Bländning:* när en hjälte får en buff blir den hjälten Förblindad 1 tur. | Buffa när putsaren är borta. Rad: "om fiende har Bländning → anfall den först". **[B]** | När bäraren får en buff blir en slumpad fiende Förblindad – kombination med Rättfärdigt slag. | `rustning.glb` + Shield som spegel. |
| **Lärling Pling** | vanlig | *Laga:* när en hjälte helas lagar Pling sig själv eller en ur verket lika mycket. | Hela med Barriär, eller Pling först. Rad: "om fiende har Laga → anfall den". **[H]** | När en fiende helas, helas bärarens svagaste allierade med hälften. Svar på alla helande fiender. | `kapa.glb` liten, skala ×0,7, mässingstint. |
| **Mätaren** | vanlig | *Lodlina:* kan inte provoceras; siktar alltid på hjälten med lägst Defense. | Provocera hjälper inte; skydda den sköra (Barriär, Försvara). **[P]** | Bärarens förmågor gör +25 % mot fienden med lägst Defense. | `rustning.glb` + Spear, smal skala. |
| **Linsväktaren** | elit | *Brännglas:* varje förmåga som träffar den ger en laddning; vid 3 bränner den hela sällskapet och nollställs. Ett anfall släcker en laddning. | Kasta inte tre i rad, eller släck med anfall. Rad: "om fiende har ≥2 laddningar → anfall". **[F]** | Bäraren laddar en lins vid varje förmåga som träffar den; vid 3 skadas alla fiender. | `rustning.glb` ×1,3, glödande lins (glow). |
| **Verkmästare Ärg** | boss | *Arbetsorder:* i början av varje runda visar han en order (Anfall / Förmåga / Försvara). Hjälten som lyder får Skyddsskal; den som inte gör det tar 10 % av max liv. | Makrot läser ordern. Rad: "om fiendens avsikt är Order: Försvara → Försvara" (⚙S). Han befrias, som Alvar. | *Arbetsorder* (kostnad): bäraren får en egen order varje runda och samma belöning och straff. | `torvald.glb` (dvärg?) med mässingsarm; befrias. |

### 2b. Vinterhusets väktare (`frost_kin`) – frön och bin som övervintrar (koncept 2)
Frostväktare som vill att ingenting någonsin vaknar. Familjens fråga: **tid och statusar** – det ni gör stannar kvar.

| Fiende | Roll | Egenskapen | Fråga / rad | Trofén | Modell |
|---|---|---|---|---|---|
| **Vinterbiet Surr** | vanlig | *Övervintrar:* Sover tills en hjälte helas; vaknar då med +50 % skada i 2 turer. | Hela, men veta att det väcker biet. Rad: "om fiende har Övervintrar och Sover → hela bara under 30 %". **[H]** | Bäraren börjar striden Sovande och vaknar när en allierad helas, med +50 % i 2 turer. Lustig risk-trofé. | Blender: rund kropp, vingar, liten (som spindeln, stela delar). |
| **Frostnypan** | vanlig | *Nyp:* träffar tar en buff från målet och ger den till Frostnypan. | Buffa efter den, inte före. **[B]** | Bärarens träffar tar en buff från målet (en gång per tur). Imma-kombo med Fingerfärdig. | `gast.glb`, isblå tint. |
| **Isspegeln** | vanlig | *Spegelvakt:* när en hjälte Provocerar provocerar Isspegeln också; hjältarnas anfall måste gå mot den. | Provocera inte medan spegeln står, eller döda den först. **[P]** | När en fiende provocerar får bäraren Utmanande 1 tur och tar −35 % skada. | `fallen_riddare.glb`, frostat glas (vit tint, glow). |
| **Snödrivan Mormor Mjäll** | vanlig | *Täcke:* hjältar som Försvarar sig blir Frusna 1 tur i slutet av sin nästa tur. | Försvara bara när det lönar sig. Rad: "om fiende har Täcke → Anfall i stället för Försvara". **[V]** | När bäraren Försvarar blir angriparen Frusen 1 tur (25 %). Väktarens kall älskar den. | `haxa.glb`, vit tint, stickad sjal. |
| **Frostfogden Hemming** | boss | *Stillhet:* medan Hemming lever räknas inga statusar ned, varken era eller deras. Under 50 %: *Tö* – alla statusar försvinner på en gång. | Lägg buffar tidigt, rena debuffar direkt; spara inget till tövädret. **[B]**/[F] | *Stillhet* (kostnad): bärarens buffar räknas inte ned, men inte hens debuffar heller, och hen kan inte renas. | `domare.glb`, isblå, kappa med frost. |

## 3. Fem fristående "minnesvärda" elitfiender
Vandrare som kan dyka upp i vilken Realm som helst, högst en per våning, med egen glöd och ett namn spelaren minns.

| Elit | Egenskapen | Frågan | Trofén | Modell |
|---|---|---|---|---|
| **Pantlånaren Bolin** | *Pant:* tar i början av striden den förmåga ni använt mest i körningen och kastar den själv mot er. Faller han får ni den tillbaka. **[F]** Siralim: Possessed Cruncher. | Klarar ni striden utan er favorit? Makrot hoppar raden (som Tystad); vilken rad tar över? | Bäraren tar pant i fiendeledarens signatur och kan kasta den en gång per strid. ⚙M | `bard.glb`, väst och våg i handen. |
| **Kopisten** | *Avskrift:* varje gång en hjälte använder en förmåga visar Kopisten den som sin nästa avsikt. **[F]** | Kasta inget ni inte vill få tillbaka; helning kopierad helar honom. | Bäraren kastar fiendens senaste förmåga en gång per strid (Charge-fri). Bygger på varje fiende. | `munk.glb`, bläckfläckar, penna i `grip_r`. |
| **Gamle Ruskig** (åskvädret) | *Blixten:* var tredje tur slår blixten ned i varje hjälte som *inte* Försvarar sig (20 % av max liv). **[A]+[F]** Siralim: The Ancestor. | Det enda stället där Försvara är svaret. Rad: "om fiendens avsikt är Blixten → Försvara" (⚙S). | När bäraren Försvarar slår blixten ned i en slumpad fiende. Ger Försvara ett skäl i varje strid. | `druid.glb`, grå tint, moln-glow kring staven. |
| **Knut och Knyt** (tvillingar) | *Bröder:* en som faller reser sig med halvt liv om den andra fortfarande står när rundan är slut. Granskningens mönster 3. | Fokus eller spridning? Belönar områdesskada och Immas pilar. Rad: "om fiende har Bröder och liv under 30 % → anfall den andra". | När en allierad faller får bäraren Pånyttfödd (en gång per strid). | `kapa.glb` ×2, olika tint (röd och blå). |
| **Fjärdingsman Fjun** | *Feg:* kan inte anfallas medan en hjälte Provocerar ("han är rädd för stora röster"). **[P]** | Släpp Provocera när Fjun är sist kvar. Rad: "om enda fiende har Feg → Anfall i stället för Provocera". | Bäraren kan inte anfallas medan en allierad Provocerar. Gör Imma eller Eira säkra bakom Brokk. | `falkenerare.glb`, för stor hatt, skala ×0,85. |

**Räkning efter förslagen** (bara nya fiender): straffar förmåga 6, helning 4, buff 5, Provocera 5, Försvara 3 (och en som
belönar Försvara), anfall 3. Ihop med granskningens fixar (Skrammel, Fastan) väger det upp "anfall inte"-övervikten.

## 4. Min topp 5

| # | Förslag | Varför | Insats |
|---|---|---|---|
| 1 | **Grinig-Gunnar (Avund)** | Läses på en rad, straffar buffar, och trofén är den roligaste att bära: den gör varje fiendebuff till din. Kombinerar med Fingerfärdig och biskopsmötet. | ½ dag (trigger `aura_applied` på motståndarsidan, ⚙S; finns troligen nästan). |
| 2 | **Gamle Ruskig** | Det enda förslaget där svaret är *Försvara* – en handling som i dag nästan aldrig är rätt. Lätt att se, lätt att svara i makrot. | 1 dag med villkoret "fiendens avsikt är X" (⚙S), som många andra förslag också använder. |
| 3 | **Trollmor Gråluva** | En klocka mot förmågor, med en trofé som kväser fiendernas kastare. Förmågor får äntligen en tidpunkt. | 1 dag (räknare per hjälte sedan sången, ⚙S) + trollmodellen. |
| 4 | **Bergakungen Grumse** | Bossregel som testar hela sällskapets makron i stället för en hjältes, och en bosstrofé med en riktig kostnad. Bär berättelsetråden (kronan). | 2 dagar (minnet av förra hjältens handlingssort, ⚙S; fas 2 med Förstenad finns). |
| 5 | **Pantlånaren Bolin** | Gör en *favoritförmåga* till insats en strid, som Siralims förseglade gems. Spelaren märker vad hen lutar sig mot, vilket är ledstjärnans fråga. | 2 dagar (⚙M: ta bort förmåga, ge fienden den, lämna tillbaka). |

Trollmodellen (Blender, ~1–2 dagar) bär sex fiender och är den största enskilda insatsen; utan den väntar familj 1.
Mät som granskningen: makrodelta med *en* svarsrad (5–15 procentenheter är målet) och `BALANS=grotta` inom ±5 pp.

## 5. Ärligt: det riskabla
- **Sömn och frost mot spelaren** (Gråluva, Mormor Mjäll, Surr-trofén): att förlora sin tur är det tråkigaste som finns
  på en telefon. Korta varaktigheter, synlig nedräkning och research K:s skydd (en handling innan nästa kontroll) krävs.
- **Arbetsorder och Stenhjärta** kräver att spelaren förstår makron på lagnivå. Kan kännas som läxa i stället för pussel;
  prova på en miniboss innan de blir bossregler.
- **Stillhet** (Hemming) ändrar varje status i striden – risk för eviga buffar och dödlägen; måste mätas mot utmattningen
  från tur 100 (1440ca3).
- **Fiender som kopierar** (Kopisten, Pantlånaren, Avund) kan ge kedjor vi inte förutser, särskilt med artefakternas
  automatiska kast. Kedjetaket (4 steg) och gränsen per tur måste gälla även fiendernas kopior.
- **Straff för Provocera och Försvara** kan göra Brokk och Väktarens kall sämre överlag. Högst en sådan fiende per grupp.
- **Brom och Isspegeln** överlappar varandra (båda gör Provocera farlig); välj en om bara en familj byggs.
- **Trollmodellen** är okänd mark: om den ser billig ut bredvid Quaternius-figurerna drar den ned hela Realmen.
  Gör en testfigur och visa den i striden innan sex fiender bygger på den.
- **För många nya makrovillkor.** Tre nya (siktar på mig, fiendens avsikt, räknare) är nog; fler gör radeditorn tung.
