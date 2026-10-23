# Roligare fiender: granskning och förslag

Underlag, inget beslutat; VD bestämmer. Läst: `data/enemies.json`, fiendeegenskaperna i `data/traits.json`,
`data/encounters.json`, `data/realms.json`, `docs/plan/0.27-fiender.md`, `docs/research/siralim.md` §4, §8c, §21.
Märkning som i 0.27-planen: **Siralim** = som originalet, **VAL** = vårt val, **GISSNING** = obeprövat.
⚙ = ny kod (S liten, M mellan). Spindlarna byggs i en annan session och berörs inte här.

**Måttstocken.** En fiende är rolig när den ställer en fråga som spelaren kan svara på före striden (trofé, sällskap)
och som en makrorad kan svara på i striden (`has_trait`, `has_status`, `hp_below`, `top/bottom_of_timeline` …).
Testet för botarna: **makrodelta** = vinst med startmakrot jämfört med samma makro plus *en* rad som svarar på fienden.
Är deltat nära noll är egenskapen dekor; är det 5–15 procentenheter skapar den ett beslut.

## 1. Betyg

3 = ställer en tydlig fråga, 2 = fungerar men passivt eller osynligt, 1 = i praktiken bara stats.

### Kryptan

| Fiende | Vad den gör | Betyg | Varför |
|---|---|---|---|
| Skelettkrigare | Benrustning: −30 % från attacker | 2 | Bra första lektion ("använd förmågor"), men samma svar som fem andra fiender. |
| Skelettbågskytt | +50 % mot mål under 50 %, Siktat skott | 2 | Ger skäl att hela tidigt. Syns mest som "det gjorde ont". |
| Gravpräst | Helar; +40 % skada per fallen allierad | 3 | Klassiskt ordningspussel: döda prästen först, annars blir den farligare för varje kamrat du fäller. |
| Gravväktare | Provocerar när någon är skadad; taggar medan den provocerar | 3 | Läsbart: vänta ut provokationen eller använd förmågor. Makrot kan svara. |
| Glödskelett | Brinner på träff, Glödregn på alla | 1 | Bara extra skada över tid. Inget att göra annat än att döda den. |
| Benspringare | Första anfallet +25 % per annan ur Benfolket | 1 | Slår en gång, sedan en vanlig snabb fiende. Hinner aldrig bli ett beslut (Speed 17). |
| Kistbärare | Barriär till familjen när den faller | 2 | Rätt idé (döda den sist), men 50 % av Defense 4 ≈ 2 barriär per medlem: osynligt sedan de små talen (0.26). |
| Mögelskelett | 40 % chans att förgifta | 1 | Slumpad nötning utan fråga. |
| Skramlaren | Den och en till Defensiva efter en attack | 2 | Ännu en "anfall inte"-fiende; överlappar Benrustning. |
| Benkolossen (elit) | Växer varje tur, Benstorm vid 3 staplar, Benmur | 3 | En klocka man ser ticka. Bra elit. Tre egenskaper är i övre kanten för en mobilruta. |
| Gravväckaren (elit) | Väcker döda med Barriär | 3 | Tydlig prioritet, Siralim-likt (Unicorn Vivifier). |
| Gravdimman (elit) | Söver den med högst Attack var 3:e tur | 2 | Går inte att förebygga, bara uthärda. Motdraget mot besvärjelser är det intressanta. |
| Benskrivaren (elit) | Mindre skada från det som redan träffat den | 3 | Tvingar makrot att variera. Men räknaren syns inte: visa staplar per förmåga i Inspect. |
| Klockaren (miniboss) | Familjen överst var 3:e tur | 2 | Bra ledare, men "var tredje tur" bör synas som avsikt, annars känns det som otur. |
| Benfursten (boss) | Väcker, vredgas under 50 % | 2 | Gränsen vid 50 % är ett beslut (spara Charges till efter). Annars mest liv. |

### Kapellet

| Fiende | Vad den gör | Betyg | Varför |
|---|---|---|---|
| Kultist | Barriär till den svagaste allierade varje tur | 3 | Gör målvalet viktigt, och biskopen är immun så länge en Kultist lever. |
| Gast | Undviker 40 % av attacker | 2 | Svaret är tydligt (förmågor) men slumpen gör det frustrerande; samma svar som Benrustning. |
| Fallen riddare | Slår tillbaka medan den försvarar sig | 3 | Läsbart fönster: anfall när den inte står i vakt. |
| Häxa | Tystar, +50 % mot tystade | 2 | En egen liten kombination. Svaret (rena eller döda först) är rimligt men osynligt i makrot. |
| Botgörare | Träffar gör målet Sårbart | 1 | Mer skada, ingen fråga. |
| Fördärvad diakon | Helar kulten och ger Läkning | 2 | En helare till. Fungerar i "Den skyddade diakonen". |
| Fanbäraren | Kulten +5 % skada per annan ur kulten | 1 | +10 % i en trepersonersgrupp märks inte. Ingen anledning att döda den först. |
| Irrbloss | Börjar överst, första träffen förblindar | 2 | Bra i Lansens anstormning, tunn på egen hand. |
| Spegelvakten | Besvärjelser studsar tillbaka 40 %+ | 3 | Den enda vanliga fienden som säger "anfall i stället". Behövs. |
| Kultens förman (elit) | Tar 50 % av skadan mot kulten | 3 | Livvakt, tydlig ordning (Siralim: Sandstone Imler). |
| Inkvisitorn (elit) | Tystar den som upprepar en förmåga | 3 | Straffar makron som bara gör en sak. Precis Siralims motdragsidé. |
| Asketen (elit) | +8 % Defense per tur, mer med De fallna | 1 | Bara seghet; låste striderna (commit d807ac9). Frågan är "har du tålamod?". |
| Den svarta lansen (elit) | +200 % första anfallet, Bärsärk när en fallen dör | 2 | Försvara första turen är ett beslut, men det syns bara om man vet. |
| Abbedissan (miniboss) | Helar och renar alla var 3:e tur | 2 | En klocka att slå före mässan, om mässan syns som avsikt i förväg. |
| Den fallne biskopen (boss) | Immun medan en Kultist lever | 2 | Tydlig regel, men bossen är farlig mest för att Charges tar slut (CLAUDE.md). |

**Det ärligaste fyndet:** åtta egenskaper säger "anfall inte" (Benrustning, Eterisk, Motstöt, Skramlaren, Taggig utmaning,
Benmur, Fastan, Antecknat), men bara Spegelvakten och Dimmans tyngd säger "kasta inte". Paladinen är en anfallare. Svaret
"använd förmågor" blir universalnyckeln, och Charges räcker hela körningen. Variationen behöver gå åt andra hållet också.

## 2. Förbättringar för de svagaste

Korta texter som de skulle stå i Inspect. Varje förslag har ett makrosvar.

- **Glödskelett** → *Glödregn:* "Glödregn gör 25 % mer skada för varje hjälte som Brinner." Glödregnet syns som avsikt.
  Beslut: rena eller Försvara innan regnet. Makro: "om allierad har Brinner → rena". ⚙S (villkor som räknar brinnande hjältar).
- **Benspringare** → *Flockjakt* (Siralim: Light Hunter): "När en annan ur Benfolket anfaller följer Benspringaren upp mot
  samma mål för 30 % (en gång per tur)." Den blir en multiplikator: döda den först, eller låt Paladinen provocera så att hela
  flocken slår i skölden. Makro: "om fiende har Flockjakt → anfall den". ⚙S (trigger `acted` för familjemedlem).
- **Mögelskelett** → *Mögelmatta:* "Förgiftade hjältar helas 50 % mindre." Behåll Sporer. Beslut: rena först, hela sedan.
  Gör Syster Alvas och Ragnhilds rening värdefull. Makro: "om allierad har Förgiftad → rena". ⚙ ingen–S (`modify_heal`).
- **Kistbärare** → behåll Sista tjänsten, men räkna på liv: "10 % av Kistbärarens liv per levande ur Benfolket." Med tre
  ur familjen ≈ 22 barriär var, nog för att märkas. ⚙ ingen (datan).
- **Botgörare** → *Gissel:* "Efter sitt anfall är Botgöraren själv Sårbar till sin nästa tur." Behåll märket. Ett fönster:
  slå den direkt efter att den slagit. Makro: "om fiende har Sårbar → anfall den". Den som plågar sig själv betalar själv
  (ondskan, inte tron, är problemet). ⚙ ingen (aura på self efter `acted`).
- **Fanbäraren** → *Kultens fana* (Siralim: Crawler + Negator): "Medan fanan står gör kulten 20 % mer skada. När
  Fanbäraren faller blir kulten Försvagad i 1 tur." Ett tydligt "döda mig först" med en belöning man ser. ⚙S.
- **Asketen** → *Fastan* (Siralim: Dragon Queen, fast för helning): "Varje gång en hjälte helas får Asketen +10 % Defense
  (högst 5)." Ingen växt av sig själv, alltså inget dödläge. Beslut: hela mindre, hela klokare, eller döda den först.
  Makro: "om fiende har Fastan → hela bara under 35 %". ⚙S (trigger `heal` på motståndarsidan).
- **Gast** (2, men samma svar som Benrustning) → *Eterisk:* "Undviker attacker, utom när den står längst ned på
  tidslinjen (den har just agerat)." Ingen slump, och villkoret `bottom_of_timeline` finns redan i makrona. Ger också
  tidslinjeflyttar ett nytt värde. ⚙S.
- **Skramlaren** → vänd den: *Skrammel:* "När en hjälte använder en förmåga blir Skramlaren och en annan ur Benfolket
  Defensiva i 1 tur." Kryptan får sin första "kasta inte"-fiende. ⚙ ingen (byt trigger).

## 3. Mönster som saknas

1. **Fiender som reagerar på vad spelaren gör** (Siralim: Dragon Queen, Dragon Soldier, Dragon Revenant). I dag bara
   upprepning (Inkvisitorn, Skrivaren) och Motstöt. Saknas: reaktion på helning (Asketen ovan), på buffar ("när en hjälte
   får en buff tar sällskapet skada"), på Provocera (en fiende som *söker* den som provocerar och slår extra hårt mot
   sköldar), på Försvara (Siralim: The Ancestor straffar den som *inte* försvarar). Varje reaktion ska kunna läsas av en makrorad.
2. **Stora slag man kan svara på.** Avsikterna syns, men makrot kan inte läsa dem. Ett nytt villkor
   **"en fiende siktar på mig"** (⚙S) gör Benfurstens Dödsdom, Lansens anstormning och Benstormen till frågor makrot kan
   besvara med Försvara. Siralim saknar det; **VAL**, Into the Breach (siralim.md §21.5).
3. **Fiender som skyddar varandra på riktigt** finns (Förmannen, Kultisten, Gravväktaren). Saknas: *måste dö samtidigt*
   (Siralim: Waspid Guardian, Phase Champion; Slay the Spire: Darklings), t.ex. ett par Benhögar som reser sig om inte båda
   faller samma runda. Belönar områdesskada och Immas pilar. ⚙S med `revive` + villkor.
4. **Fiender som tar troféerna på allvar.** Ingen fiende rör troféerna i dag, fast de är spelets kärna.
   - *Beslag* (Siralim: Bloodstone/Jewel Cruncher förseglar och kopierar): motdrag hos Inkvisitorn från djup 2: "I början av
     striden lägger Inkvisitorn beslag på trofén hos sällskapets starkaste. Den verkar för Inkvisitorn tills hon faller."
     Spelaren märker vad trofén var värd, och segerskärmens "Det här avgjorde striden" får en historia. ⚙M.
   - *Igenkänning* (**VAL**, inte Siralim): fiender av samma sort som en burit trofé anfaller bäraren först ("Han har
     Kaptenens finger!"). Ger Provocera ett nytt syfte och en replik. ⚙S. Pröva först som ren smak.
5. **Charges som insats** (Siralim: Possessed Cruncher förseglar gems). Charges räcker hela körningen, så en fiende som
   förseglar en förmåga *för striden* kostar på riktigt. Sparsamt: en elit, som motdrag.
6. **Spelaren kan vända fiendens egenskap mot den** (Siralim gör det sällan, **VAL**): Häxans tystnad, Botgörarens Sårbar
   och Glödets Brinner kunde någon gång gå att ta (Immas Fingerfärdig gör det med buffar). Bra kombinationsmotor för troféer.

## 4. Topp 5 att göra först

| # | Förslag | Insats | Mät med botarna |
|---|---|---|---|
| 1 | **Fanbäraren** (20 % och Försvagad när den faller) + **Kistbärarens** barriär på liv | ½ dag, mest data | Makrodelta med raden "anfall den med Kultens fana"; vinst i `chapel_2f`, `chapel_3e`, `crypt_2e`, `crypt_3d`; MACRO får inte falla mer än ~5 pp. |
| 2 | **Asketen** på helning i stället för tid | ½–1 dag (⚙S) | `BALANS=elitgrupper` för `chapel_e4`: stridslängd, andel strider över 100 turer (ska bli 0), vinst med och utan helare i sällskapet. |
| 3 | **Benspringarens Flockjakt** + **Glödregn per brinnande** | 1 dag (⚙S) | Makrodelta i `crypt_2d`, `crypt_e5`, `crypt_e6` (anfall springaren först / Provocera) och `crypt_2b`, `crypt_2c` (rena före regnet); skada tagen per strid. |
| 4 | **Gasten på tidslinjen** + **Botgörarens Gissel** + **Skramlaren mot förmågor** | 1 dag (⚙S) | Andel skada från förmågor kontra attacker per Realm före/efter (ska närma sig jämvikt); makrodelta med `bottom_of_timeline` och "har Sårbar"; `BALANS=grotta` vinst inom ±5 pp. |
| 5 | **Beslag** som Inkvisitorns motdrag | 2 dagar (⚙M, trait av på hjälte och på fiende, visning) | `chapel_e3` på djup 2: vinst med och utan; `trait_stats` för den beslagtagna trofén; hur ofta Inkvisitorn dödas först med TUNED jämfört med i dag. |

Efter varje steg: kör `BALANS=grotta` för båda Realms och `BALANS=forsta`, så att introts väg inte blir svårare
(den ska ligga kvar kring 80 %). Det viktigaste måttet är ändå ledstjärnans: byter spelaren trofé eller makrorad
efter att ha mött gruppen? Ett enkelt ombud är makrodeltat ovan; det riktiga svaret kommer från telefonen.
