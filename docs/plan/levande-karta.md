# Den levande kartan – plan för ett första test (skriven 2026-10-22, inte påbörjad)

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
