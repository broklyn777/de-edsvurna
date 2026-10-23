# Den levande kartan – plan för ett första test (skriven 2026-10-22; första testet byggt 2026-10-23, se Resultat)

Ursprung: tråd 3 (`docs/ideer/trad3-losa-ideer.md`) och ChatGPT:s research L (`docs/ideer/chat-familjer-karta-grottan.md`).
**Avvikelse från Siralim:** Siralim har ingen värld som förändras mellan körningarna. Vi provar det för att samlandet
och djupen ska få en berättelse – men bara som ett litet test först.

## Frågan testet ska svara på
Känns världen levande, eller känns kartan som en syssla? Inget annat. Blir svaret nej har vi bara lagt några dagar.

## Testet: två Realms, inga nya familjer
- Varje Realm (Kryptan: Benfolket; Kapellet: Kultens folk och De fallna) får `growth` 0–4 i profilen. Start: 1 och 1.
- **Efter varje nedstigning med minst en vunnen strid** (aldrig i verklig tid): den Realm man gick till sjunker 2 steg
  (lägst 0) om dess quest klarades, annars 1; den andra växer 1 steg. En Realm på 0 vilar en nedstigning.
- **Styrkan i strid:** fienderna som en mildare instabilitet (förslag +6 % stats per steg) och bättre fynd och
  troféchans per steg. Mäts med botarna innan något bestäms.
- **Steg 4:** en förvriden boss (t.ex. "Den svärtade Benfursten") med en egen trofé visar sig. Realmen står still på 4
  tills man går dit; ingen spridning vidare i testet. Varning på steg 3: "Nästa gång kan något vakna där nere."
- **Visas utan siffror:** fördärvet över området blir tätare, svarta märken och fler eldar; en rad före avfärd
  ("Går ni till kapellet får Benfolket i kryptan andas ut") och efter hemkomsten samma orsak och vad som ändrades.
  Imma eller Gorm säger något när ett steg ändras, högst en replik.
- Inga permanenta förluster: byar och tjänster försvinner aldrig.

## Känd begränsning
Med två Realms blir det en pendel: slår man den ena växer den andra. Cirkeln (troll → skelett → spindlar → troll)
kräver en tredje familj. Testet visar känslan, inte hela idén.

## Ordning
1. VD provspelar 0.30.x.
2. Testet ovan (profilfält, kampanjkartans bild, styrkan i `battle_opts`, en förvriden boss, botar).
3. Om det känns rätt: spindlarna som tredje familj (research K), sedan trollen.

## Resultat: första testet (2026-10-23, grenen `levande-karta`, skuren från test-0.30)

Byggt: `src/game/living_map.gd` (`LivingMap`), fälten `Profile.growth`, `growth_rest`, `growth_last`, `growth_news` (gamla
sparfiler får startvärdet 1), `RunState.growth`, `twisted`, `wins`, `realm_quest_done`, `Run.end_descent()` (förlust, ge
upp, gå hem och klarad körning; inte första nedstigningen eller Övningsgården), kampanjkartans bild och texter, den
förvridna bossen i kryptan och botarna. Tester: `tests/test_living_map.gd`.

### Egna val
- **Upplåst = besökt.** En Realm växer först när man har gått ned där en gång. Annars skulle en ny spelare möta ett kapell
  på steg 4 första gången.
- **Med tre Realms växer bara den som legat orörd längst** (`growth_last`). Planens regel (alla andra växer) mättes först:
  karriärbotarna (som växlar Realm varje gång men ofta förlorar, och då sjunker Realmen bara 1) drev upp kryptan till
  3,7 i snitt efter 18 nedstigningar och mötte den förvridna bossen 2,4 gånger per profil. Med "äldst växer" ligger
  kartan på 0–2 när man växlar (0,15 förvridna bossar per profil), och den man undviker når 4 (se KARRIAR_REALM=lagst).
  Med två Realms är reglerna desamma som i planen.
- **Steg 0 och 1 är dagens strider.** Inget blir lättare än balansen; steg 0 är bara vila och ett tunnare bläck.
- **Styrkan: +2 % stats per steg från steg 2** (×1,02 / ×1,04), och **steg 4 = steg 3** i stats: där är det den förvridna
  bossen som är hotet. Planens +6 % var alldeles för mycket: kryptans körningar föll från 35 % till 12/5/0 % (steg 2/3/4).
- **Bytet från steg 2:** troféchans +5 procentenheter per steg, bärnstenschans +10 procentenheter per steg och +1 bärnsten
  från steg 3, trick och Nether Stones +25 % per steg (`Forge.roll_finds` `growth`).
- **Vila:** en Realm som når 0 växer inte nästa nedstigning; vilar den, växer den näst äldsta.
- **Den svärtade Benfursten** (`bone_lich_black`, mötet `crypt_twisted`): Benfurstens regler, Resistent, Odödlig vrede och
  Svart märg (Barriär 8 % av max liv när någon i hans följe faller), stats 190/12/12/2/9 (Benfursten 180/11,8/11,8/2/9).
  Sotsvart kåpa, järnkrona, röda ögon och rött sken. Hans trofé **Svärtad krona** (boss): när någon i sällskapet faller
  sveper bäraren fienderna med Benstorm, men bärarens helningar är 25 % svagare. Ges direkt vid första segern (inte efter tre
  som Siralims Masters), eftersom han bara visar sig på steg 4. Kapellet och Lunden har ingen förvriden boss än; där är
  steg 4 bara steg 3 som står still.
- **Texterna:** raden före avfärd i panelen ("Går ni hit trängs Benfolket tillbaka. Under tiden växer fördärvet i
  kapellet." och på steg 3 "Nästa gång kan något vakna i kryptan.") och rutan "Medan ni var borta" efter hemkomsten, en rad
  per Realm som ändrades, med högst en replik (Imma om hon finns, annars Gorm) för den viktigaste ändringen
  (`dialog.json` "living_map", repliker med id). Rutan visas en gång och försvinner vid nästa nedstigning.
- **Bilden:** vinjettens bläck når längre in och blir mörkare per steg (shaderns `growth`), svarta stänk spiller över ramen
  ut på pergamentet och fiendens eldar fladdrar i området från steg 2; på steg 4 med en förvriden boss ett rött dödskallesigill.

### Botsiffror
`BALANS=levande` (djup 1, väntad nivå 3, fyra hjältar med startmakron, 100 hela grottkörningar per ruta, MACRO/TUNED):

| | steg 1 (= 0) | steg 2 | steg 3 | steg 4 |
|---|---|---|---|---|
| Kryptan | 35/52 % | 28/45 % | 21/31 % | 13/14 % (förvriden boss) |
| Kapellet | 48/45 % | 29/37 % | 30/32 % | 30/32 % |
| Lunden | 48/65 % | 34/62 % | 30/54 % | 30/54 % |

Bossmötet ensamt med fulla Charges (nivå 5): Benfursten 100 %, Den svärtade Benfursten 98 % på steg 4. Han fäller körningar
genom nötningen, inte i en ren strid. Prövat och förkastat: +6 % per steg (kryptan 12/5/0 %), +3,5 % (22/15/0 %), och en
första förvriden boss med 216 i liv och 13 i Attack (kryptan steg 4: 3/13 %).

`SOAK=karriar` (40 profiler × 18 nedstigningar, Realm i tur, botarnas hemmaval som förut):
- Kurvan med kartan på och av är densamma inom bruset (vinst per nedstigning 25–63 % på, 23–63 % av; djupet efter 18
  nedstigningar 6,0 i båda). Vinst per steg i den Realm man gick till: steg 0 48 %, steg 1 46 %, steg 2 44 %, steg 3 34 %,
  steg 4 25 % (8 nedstigningar). Kartan i snitt (krypta/kapell/lund) ligger på 0–2,9 per Realm, oftast under 2, och kryptan går i en sågtand eftersom den besöks var tredje gång.
- `KARRIAR_REALM=lagst` (går alltid till den lugnaste): kryptan står på 4 från nedstigning 5 och lunden når 3,6; boten
  slipar kapellet på steg 0. Ingen förvriden boss möts, eftersom boten aldrig går dit.
- Inga nya soak-fel. Kontrollfelen "har inte fått agera på 17–25 turer (frozen)" i crypt_3 finns lika ofta med kartan av
  (Benstormens frysning hos Benfursten); ett av dem kom i crypt_twisted, som har samma Benstorm.

### Öppna frågor till VD
1. Känns kartan levande eller som en syssla? (Testets enda fråga.)
2. När man växlar ligger världen mest lugnt (0–2), och den förvridna bossen kommer bara om man undviker en Realm i tre
   nedstigningar. Ska den komma oftare (t.ex. att två Realms växer när man förlorar)?
3. Steg 4 i kryptan halverar ungefär vinsten för botarna. Är det rätt pris för en egen bosstrofé, eller ska han vara mildare?
4. Ska kapellet och Lunden få egna förvridna bossar (förslag: Den svärtade biskopen, Vävmoderns förvridna drottning)?
5. Bytet syns inte i siffror för spelaren (planens "utan siffror"). Räcker det att Imma säger att det är farligare och
   rikare, eller behövs en ledtråd om bättre fynd?
