# Prompt till chat – idéer för byggdjup

Kopiera allt under strecket.

---

Jag bygger ett mobilspel (Android först) i Godot: ett party-RPG i klassisk fantasy där spelaren är raidledare för fyra hjältar (Warrior/tank, Priest/healer, Mage och Rogue) mot en boss. Striden går i realtid med WoW Classic-känsla (global cooldown, cast bars, bossmekaniker man måste avbryta eller skydda sig mot) och har en taktisk paus. Spelaren styr med fem knappar (Shield Wall, Flash Heal, Kick, Pyroblast, Bloodlust). Resten sköts av hjältarnas egen AI.

Jag vill ha **ett byggdjup som i Siralim Ultimate**. Här är ett Siralim-bygge som visar vilken sorts djup jag menar:
https://berated-bert.github.io/siralim-planner/?b=90b5af4a40c12e2e4aa7896fc99c922588579fefddcaf28dd46da59418483a5f1fe59ce03ee7496cbb4c6e2480670bf2e2dfb08d0bf7&r=______

Det jag gillar med bygget:
- En egenskap ändrar förutsättningen för en annan (*Outcast No Longer* gör alla till skelett så att *Master of Skeletons* gäller hela laget).
- Kedjor där ett anfall föder fler anfall (kritisk träff → extra anfall → ny kritisk träff …).
- Snöbollar som gör laget starkare under striden.

**Så här fungerar mitt system i dag:**
- Varje hjälte väljer 1 av 3 klassegenskaper före striden och får dessutom 1 artefakt. Det finns 8 artefakter, och varje artefakt kan bara bäras av en hjälte.
- En egenskap är data: den lyssnar på en händelse i striden (`damage`, `heal`, `cast_end` med resultatet `interrupted`, `aura_applied` …) och kör effekter (`damage`, `heal`, `aura`, `mana`) när villkor stämmer (vem som är källa eller mål, kritisk träff, under X % liv, har en viss aura). Den kan också ändra siffror (`modify_damage`, `modify_damage_taken`, `modify_heal`).
- Egenskaper kan sätta igång varandra i kedjor (max 4 steg).
- Exempel på en kedja: Rogue avbryter med Kick → bossen blir *Blottad* (tar 15 % mer skada) → Mages träffar mot blottade mål är alltid kritiska → Priest får mana av varje kritisk träff.
- Simulerade spelare (botar) kör tusentals strider headless för att hitta trasiga eller värdelösa kombinationer.

**Vad jag vill att du tänker på:**
1. Vilka 3–5 *principer* gör Siralims byggen beroendeframkallande, och vilka passar ett spel i realtid där spelaren också måste trycka själv?
2. Föreslå ett system med **taggar** (t.ex. skola: Helig/Eld/Skugga/Natur, eller ras/ordning) och 6–8 egenskaper som räknar på taggarna, inklusive minst två *regelbrytare* i stil med Outcast No Longer.
3. Föreslå 4–6 egenskaper som **växer under striden** (snöbollar) utan att göra striden trivial.
4. Hur håller man det **läsbart på en mobilskärm** när många egenskaper slår till samtidigt?
5. Vad ska jag akta mig för (oändliga kedjor, en enda bästa kombination, spelaren förstår inte varför hen vann)?

Skriv egenskaperna kort, med namn, en mening regeltext och vilka andra egenskaper de samverkar med. Klassisk fantasy-ton, gärna svenska namn.
