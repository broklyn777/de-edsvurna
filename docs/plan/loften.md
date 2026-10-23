# Löften per nedstigning – plan (2026-10-23, inte beslutad)

Underlag för VD:s beslut. Idén kom från Claude-chattarna två gånger (`docs/ideer/claude-kreativ-30-ideer.md`,
`claude-kreativ-30-ideer-2.md`). Inget är byggt.

## Idén i korthet
Före en nedstigning lovar Paladinen något för hela körningen, t.ex. "Ingen ska falla". Löftet är en **regel som ändrar
hur man vill bygga laget**, inte en siffra:
- **Hållet** ger det en fördel under körningen och lite mer silver, som instabiliteten.
- **Brutet** blir det en **ödmjukare form** med en annan, mindre regel för resten av körningen. Aldrig ett straff och
  aldrig något mörkt: ett brutet löfte blir något ödmjukare.
- **Hållet hela körningen** växer det ett steg (högst 3, sparas i profilen), så att löftet blir starkare nästa gång.

Varför det passar: spelets namn blir en regel, det hänger ihop med kallen, och det följer ledstjärnan (regler som
ändras, hellre än mer skada). Det ligger nära Siralim i andan: frivillig svårighet mot belöning, som Realm Instability,
fast som en regel i stället för siffror.

**Namnet:** "eden" är redan kallet ("Avlägg din ed vid Kallets altare"), så det heter **löfte**.

## Var man väljer
På kampanjkartan, bredvid instabiliteten: LÖFTE: INGET → en lista. Högst ett löfte per nedstigning. Det syns i stridens
regelrad ("Löfte: Ingen ska falla") och på rumskartan, och den ödmjuka formen när löftet är brutet. Gorm säger något
första gången (introts ton; ett löfte öppnas efter introt, som Värdshuset).

## Tre löften för första provet

| Löfte | Regeln | Hållet (fördel) | Brutet blir | Bryts när |
|---|---|---|---|---|
| **Ingen ska falla** | – | I början av varje strid får den svagaste en Barriär (10 % av max liv; steg 2: 15 %, steg 3: alla) | **Den som föll reser sig** – en gång per körning väcks den första som faller med 30 % liv | en hjälte faller |
| **Jag helar inte** | Helningsförmågor går inte att välja; makrorader med dem hoppas över (som Tystad) | Paladinens direkta attacker helar den svagaste med 25 % av skadan (steg 2: 35 %, steg 3: 50 %) | – (kan inte brytas) | – |
| **Raka vägen** | Högst 2 vanliga grupper per våning (elit, Nemesis, boss och questens grupper räknas inte) | Questens silver ×2 och ett extra fynd vid trappan och bossen | **Omvägen** – questens silver som vanligt, ingen förlust | en tredje vanlig grupp anfalls |

**Raka vägen** svarar också på provspelet: i dag lönar det sig att raka av grottan (botarna som backar vinner mindre).
Ett löfte som belönar att gå direkt gör det till ett val i stället för en ny regel för alla.

Fler att pröva senare: "Ledaren sist" (ledaren, eliten eller bossen skadas inte förrän de andra har fallit; fler
elittroféer), "Jag går först" (Paladinen överst på tidslinjen varje strid men tar mer skada), "Barmhärtighet" (De fallna
ger upp i stället för att dö och lämnar en annan trofé – kräver trofévarianter, se "Den sparade" i
`docs/ideer/claude-kreativ-troféer.md`).

## Risken: alla väljer det lättaste
- Belöningen (silver, fynd) sätts efter vad löftet kostar, mätt med botarna per Realm, som våningsreglernas silver.
- Löftena är olika svåra för olika lag: "Jag helar inte" är lätt för ett anfallslag och hårt för ett lag med Alva. Det är
  avsikten – löftet ska få spelaren att vilja bygga om.
- Inget löfte är obligatoriskt. Det finns ingen bästa väg, bara en till.

## Hur det byggs (teknik)
- `data/vows.json`: id, name, text, `restriction`, `held` (trait-id), `humble` (trait-id), `breaks_on`, `silver`, `steps`.
- Fördelarna är vanliga egenskaper i `traits.json` med `"scope": "party"`, som kallets kärna. Stridsmotorn behöver nästan
  inget nytt.
- `RunState.vow`, `vow_broken`; `battle_opts()` lägger till hållet eller ödmjukt; sparas med körningen.
- "Jag helar inte": samma väg som Tystad (`is_silenced`) men bara för förmågor med helning.
- "Raka vägen": `RunState` räknar vanliga strider per våning; kortet i grottan varnar innan löftet bryts.
- `Profile.vow_steps` (id → steg 0–2), höjs när körningen klaras med löftet hållet.
- Botarna: `BALANS=loften` mäter varje löfte mot inget löfte (vinst, silver), som `perk_report.gd`.
- Tester: bryts av rätt händelse, ödmjuk form efter brott, steg sparas, makrorader hoppas över.

Uppskattning: ungefär en dag för de tre löftena, valet på kampanjkartan, regelraden, botarna och testerna.

## Minsta test
De tre löftena utan steg (stegen först om det håller). Frågan till VD efter ett par körningar: **ändrade löftet hur du
ville bygga laget eller gå i grottan?** Om ja: steg, fler löften, Gorms repliker. Om nej: det blev bara en ny siffra,
och vi lägger ned det.

## Frågor till VD
1. "Löfte" som namn, eller något annat?
2. Ska stegen vara permanenta i profilen, eller bara synas i Biblioteket som en krönika?
3. Raka vägen eller ett annat tredje löfte?
