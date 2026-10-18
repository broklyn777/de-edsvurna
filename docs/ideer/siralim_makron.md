# Siralim Ultimates makron – vad vi vet

Undersökt 2026-10-18 inför makrosystemet i rpg007. Varje punkt har en källa och en säkerhetsgrad:
**Bekräftat** (officiell text eller skärmdump ur spelet), **Troligt** (spelare som beskriver samma sak),
**Okänt** (motstridigt eller inte belagt).

Källor:
- [Codex Reference](https://steamcommunity.com/sharedfiles/filedetails/?id=2197484456) – spelets egen Codex-text, avsnittet "Macros".
- [Skärmdump av Macro Editor](https://steamcommunity.com/sharedfiles/filedetails/?id=3356475192) (från tråden nedan).
- [Macro Conditions Question](https://steamcommunity.com/app/1289810/discussions/0/4702413966613159824/)
- [how does the macro system work?](https://steamcommunity.com/app/1289810/discussions/0/3196988242386085605/)
- [macros question](https://steamcommunity.com/app/1289810/discussions/0/3274688023496201083/)
- [I need help with a macro please.](https://steamcommunity.com/app/1289810/discussions/0/598521912287570539/)
- [Question about Macros](https://steamcommunity.com/app/1289810/discussions/0/3196988242369333004/)
- [Siralim Ultimate 2.0 – patchnoter](https://www.thylacinestudios.com/blog/siralim-ultimate-2-0-patch-notes),
  [App Store-versionshistorik](https://apps.apple.com/gb/app/siralim-ultimate/id1601114348)

## Grundstruktur

| Regel | Säkerhet | Källa |
|---|---|---|
| Ett makro är en lista med upp till **20 rader**. | Bekräftat | Codex |
| Makron skapas i en egen meny och **tilldelas sedan en figur** ("Assign Macro"). Makrot är alltså ett eget objekt som pekas ut per figur. | Bekräftat | Codex |
| Makrot körs bara när figuren använder kommandot **"Macro"** på sin tur. Det tar inte över automatiskt. | Bekräftat | Codex, forum |
| Man kan sätta figurens **standardhandling till Macro**. I turboläge används standardhandlingen; annars trycker man bekräfta. Det finns ingen inbyggd helautomatik. | Troligt | forum (två trådar) |
| Raderna prövas **uppifrån och ned**. Den första raden som ger ett positivt resultat utförs och **turen tar slut**. | Bekräftat | Codex |
| En rad har tre delar: **en grupp figurer att pröva**, **ett villkor** att pröva dem med och **en handling**. | Bekräftat | Codex |

## Rad: subjekt

Ur skärmdumpen av Macro Editor (kolumn 1): *If this creature, If any ally, If any enemy, If ally (1)–(6),
If ally (all), If enemy (1), (2), (3) …* (listan fortsätter nedanför bilden – troligen enemy (4)–(6) och
enemy (all)). **Bekräftat** för de synliga.

- "any" = minst en i gruppen uppfyller villkoret. "(all)" = alla måste uppfylla det. **Troligt** (namnen).
- Vilken figur som blir "that creature" när flera matchar "any": **Okänt.**

## Rad: villkor

| Villkor | Säkerhet | Källa |
|---|---|---|
| `has < 10% Health` … `has < 90% Health` i steg om 10 | Bekräftat | skärmdump |
| `has > X% Health` | Troligt | Codex-exemplet "> 20% Health", forum |
| `Health < 100%` | Bekräftat | 2.0-patchnoter |
| har / har inte en viss buff eller debuff | Troligt | forum |
| är högst / överst på tidslinjen | Troligt | forum |
| `Is Not At Top of Timeline`, `Is Not At Bottom of Timeline` | Bekräftat | App Store 2.0 |
| `Resurrection Count`, `Death Count` | Bekräftat | App Store 2.0 |
| `Has Trait`, `Doesn't Have Trait` | Bekräftat | App Store 2.0 |
| Fullständig lista | **Okänt** | – |

## Rad: handling

Ur skärmdumpen (kolumn 3): **attack…, defend, provoke, cast…, skip turn, test next line.** Bekräftat.

- "…" betyder att man väljer vidare. Codex-exemplen: *"attack a random enemy"* och
  *"cast Healing on that creature"* (= figuren som matchade villkoret). **Bekräftat** att de målen finns.
  Fullständig lista över mål: **Okänt.**
- `cast` kräver att figuren har besvärjelsen (spell gem). Codex: "as long as it has the spell equipped".
  Bekräftat. Vad som händer om den saknas (raden hoppas över eller misslyckas): **Okänt.**

## Flera villkor: "test next line"

`test next line` är en **handling**. Raden utför alltså ingenting själv utan går vidare till nästa
rad. Det gör att man kan kedja villkor (OCH). **Bekräftat** att handlingen finns.

Om kedjan minns *vilken* figur som matchade (t.ex. "en allierad utan Blighted" **och** "under 10 %" ska
vara samma allierade), är **Okänt**. Spelarna i forumtråden är oense, och ingen har belagt det.

## När inget passar

En spelare citerar spelet: "have no macro that meet the requirements". Figuren gör då inget automatiskt
och spelaren får välja själv. **Troligt** (en källa).

## Förslag till rpg007

Det här bygger vi likt originalet:

- Makron som egna objekt med upp till 20 rader, tilldelade per hjälte. Standardhandling per hjälte kan
  vara Makro.
- Rader med subjekt (*denna hjälte, någon allierad, någon fiende, allierad 1–4, alla allierade,
  fiende 1–6, alla fiender*), villkor och handling (*Anfall…, Förmåga…, Försvara, Provocera, Hoppa över,
  Pröva nästa rad*), med mål som *den som matchade, slumpvis fiende, fiende N* osv.
- Uppifrån och ned; första positiva raden utförs och turen tar slut.
- Inget passar: hjälten stannar och väntar på spelaren, med meddelandet "Inget makro passade".

Avvikelser som behöver ditt beslut:

1. **Förklaringen.** Siralim har en stridshistorik, men visar inte varför makrot valde en rad. Vi lägger
   till en logg: "Syster Alva valde Helande ljus eftersom rad 2 matchade: Brokk har < 40 % liv." Det är
   ett tillägg, inte en förenkling.
2. **Förmågor i stället för spell gems.** I Siralim kan en figur ha flera besvärjelser. Våra hjältar har
   en signaturförmåga var. Då blir *cast…* fattigare. Förslag: ge varje hjälte 2–3 förmågor
   (besvärjelser) så att makrona får riktiga val.
3. **"Any" med flera träffar** och **test next line som minns figuren**: tills vi vet hur originalet gör
   väljer vi den första i ordning (hjältens plats) och låter kedjan minnas figuren. Det bör kontrolleras
   i spelet.
4. **Helautomatik.** Siralim kräver ett tryck per tur även med makro. Vi har redan Auto; med makron
   blir Auto "använd makrot för alla" och stannar när inget passar.
