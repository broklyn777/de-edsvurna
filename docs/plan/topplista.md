# Topplista (utredning, ingen kod)

Status: förslag, inget beslutat. Siralim Ultimate har ingen topplista; allt nedan är *vårt val* om vi gör något.

## 1. Vad mäter man i ett spel utan poäng?

Profilen sparar redan `realm_depth`, `best_depth`, `descents`, `boss_wins`, `quests_done`, `heroes` (strider, vinster, dödsfall).
Det som saknas är per-körning-data: en körning skriver idag bara `run.cfg` som tas bort vid slut.

| Mått | Rättvist? | Fusk lokalt | Kommentar |
|---|---|---|---|
| Djupaste klarade djup (per Realm) | Ja, men går mot "grinda nivåer" | Lätt (redigera cfg) | Redan sparat. Beror på hur länge man spelat. |
| Högsta instabilitet klarad (på djup N) | Ja, bra svårighetsmått | Lätt | Kräver ny sparad rad. |
| Löften hållna i en klarad körning | Ja, ren skicklighet | Lätt | Kräver `vow_broken`-historik. |
| Färre hjältar (Paladinen ensam / +1) | Ja, självvald utmaning | Lätt | Svårt att jämföra med nivåer. |
| Snabbaste klarade Realm (strider/turer) | Delvis: slump (frö) och nivåer styr | Lätt | Bättre med dagligt frö. |
| Dagligt frö (samma grotta för alla) | Mest rättvist, samma slump | Medel | Grotta och strid är seedade, så tekniskt nära. Nivåer/troféer skiljer fortfarande. |

Slutsats: inget rent lokalt mått är fusksäkert. Rättvisast blir en *klass* (t.ex. "nivå 1-hjältar, djup 3, instabilitet 2, löfte X, dagligt frö") där nivåer
inte spelar roll; annars vinner den som grindat längst. Fusksäkra kan man bara bli med server som återspelar körningen (dyrt), eller genom att
skicka in ett frö + alla val och köra om striden på servern (vår strid är ren logik, så det går i princip, men är stort).
Rimlig hållning: acceptera fusk, håll listorna små och sociala.

## 2. Tre nivåer

**(a) Lokal krönika/rekordtavla per profil, i Biblioteket (Broder Alrik).** Ingen nät.
- Ny lista `Profile.chronicle`: en rad per avslutad körning (Realm, djup, instabilitet, löfte, strider, turer, sällskap, utfall, datum) + rekord (djupast, minst strider, högsta instabilitet).
- Kostnad: låg. Nackdel: ingen jämförelse med andra; fusk spelar ingen roll. Passar tonen (krönika, "edsvurnas bok").

**(b) Google Play Games Services (PGS) leaderboards.**
- Tillägg: `godot-play-game-services` (godot-sdk-integrations, MIT). Annonserat med Godot 4.3+-stöd för att visa topplista, skicka poäng, hämta topp/spelarcentrerade poäng. Tidigare 4.2-version och ett äldre itch.io-tillägg (Thunder Plugins) är markerade som föråldrade. Jag har inte verifierat senaste release eller att det bygger med Godot 4.7.2 och vår Gradle-lösa export. Prov krävs.
- Vår export är **utan Gradle** (`use_gradle_build=false`). Godots Android-tillägg (AAR) kräver normalt Gradle-bygge, så detta är en verklig risk och kan tvinga oss till en större byggändring (JDK 17 finns, men Gradle-bygge på macOS 13 är ny terräng).
- Krav: Play Console-konto (engångsavgift, 25 USD), appen skapad i Play Console med PGS-projekt, leaderboard-id:n, OAuth-klient kopplad till signeringsnyckeln (vi signerar med debug-nyckel; Play kräver egen uppladdningsnyckel/Play App Signing), testare tillagda. Sign-in v2 är det nya spåret (v1-SDK tas bort 2026), så tillägget måste ha v2; kontrollera.
- Nackdelar: Android-bara (iPhone senare = Game Center, dubbelt arbete), kräver Google-inloggning, appen måste i praktiken ligga på Google Play (minst internt test), sekretesspolicy. Fusk: klienten skickar poängen, så redigerade filer kan skicka falskt; PGS har inget skydd.

**(c) Egen server.** En liten tjänst (t.ex. en serverlös funktion + databas), `POST /score` med profil-id, frö och mått, `GET /top`.
- Kostnad: drift, konton/anonyma id, missbruk, GDPR (namn på paladinen är personuppgift i lista), moderering av namn. Fusk lika enkelt som (b) om inte striden körs om på servern. Mest arbete, mest kontroll, plattformsoberoende.

## 3. Passar det? Är det värt det nu?

Ärligt: nej, inte som mål nu. Ledstjärnan är att *bevisa att det är roligt att kombinera* innan vi bygger innehåll. En topplista belönar
en annan sak (optimera ett mått) och risken är att den lockar mot "bästa bygget" snarare än "kul bygge". Siralim har ingen och dess fans
tävlar ändå via själv-påhittade utmaningar, vilket är precis vad Löften (0.30.17) redan är. Nät, konton och Play-krav drar också uppmärksamhet
från spelkänslan. Däremot är en **krönika** tonmässigt rätt (Alrik skriver ner dina bedrifter) och ger spelaren ett eget mål utan tävling;
den gör också att vi *får data* om hur folk spelar (Löften, instabilitet) som hjälper balansen.

Det som skulle ändra bedömningen: att fler än du och några vänner spelar, och att Play-utgivning ändå är på gång (då är (b) billigare).

## 4. Rekommendation och arbetstid

1. **(a) Krönika nu, i liten form** (ca 0,5–1 dag): spara en rad per avslutad körning (`Profile.chronicle`, tak ~50 rader), flik "Krönikan" i Biblioteket med rekord och senaste körningar. Texten från Alrik. Prov i `tests/`.
2. Lägg i raden de fält en framtida server skulle behöva (frö, djup, instabilitet, löfte, strider, sällskapsstorlek, spelversion, hash av valen), så att (b)/(c) kan byggas utan omarbete (+1–2 timmar).
3. **(b) Skjut upp** tills spelet ligger på Google Play: 2–4 dagar om tillägget går att bygga utan Gradle, annars 4–7 dagar (Gradle-byte, signering, Play Console-uppsättning), plus väntetider hos Google. Börja med ett litet försök: bygg tillägget i en grenad kopia och se om APK:n startar.
4. **(c)** Avrådes nu: 1–2 veckor plus löpande drift.

Om man ändå vill ha tävling utan server: delbart "dagligt frö" som text/bild-kort (frö + resultat) att skicka i chatten (ca 1 dag). Låg risk, social, och fusk spelar ingen roll.

## Källor

- godot-play-game-services (Asset Library): https://www.godotengine.org/asset-library/asset/2440
- Samma tillägg, Godot-butiken: https://store.godotengine.org/asset/jacob-ibanez-sanchez/google-play-games-services-for-godot/
- Äldre Thunder Plugins-tillägget (föråldrat): https://thunderplugins.itch.io/google-play-services-for-godot-4
- Google, Sign-in v2 för Android-spel: https://developer.android.com/games/pgs/android/android-signin
- Google, v1-leaderboards och utfasningen av v1-SDK: https://developer.android.com/games/pgs/v1/android/leaderboards
- Kodrepo (ej läst, enligt söksvaren): github.com/godot-sdk-integrations/godot-play-game-services
