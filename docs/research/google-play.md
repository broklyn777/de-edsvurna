# Google Play: vad som krävs för att publicera De edsvurna

Research 2026-10-24 (gren `research-google-play`, från `test-0.30`). Inga byggen kördes; läget nedan kommer
från `export_presets.cfg`, `project.godot` och en granskning av den senast exporterade APK:n
(`export/rpg007.apk`, version 0.29.4, med `aapt2`, `zipalign` och en ELF-läsning av `.so`-filerna).
Policyerna ändras ofta – läs om källorna innan något skickas in. Sådant jag inte kunde bekräfta i en
officiell källa står som **antagande**.

## 1. Läget i dag

| Sak | Nu | Krav för Play |
|---|---|---|
| Format | APK, `gradle_build/use_gradle_build=false` | **AAB** för nya appar (sedan aug 2021) → Gradle-bygge krävs |
| Arkitektur | bara arm64-v8a | 64-bit krävs; arm64-only är tillåtet (x86_64 behövs bara för emulatorer/Chromebooks) |
| Target SDK | 36 (APK:n säger `targetSdkVersion:'36'`, compileSdk 36) | 36 för nya appar och uppdateringar från 31 aug 2026 – **uppfyllt** |
| 16 KB-sidor | `libgodot_android.so` och `libc++_shared.so`: alla LOAD-segment `align 0x4000` (16 KB); `zipalign -c -P 16 4` godkänd | Krav för uppdateringar från 1 feb 2027 – **uppfyllt för APK:n**, kontrollera AAB:n igen |
| Signering | debug-nyckeln (`~/.android/debug.keystore`) | Egen **uppladdningsnyckel**; Google håller appens signeringsnyckel (Play App Signing) |
| Paketnamn | `se.rpg007.prototype` | Permanent efter första uppladdningen – byt före (§7) |
| Appens namn | `config/name="rpg007"`, `package/name="rpg007"` | "De edsvurna" (namnet under ikonen) |
| Behörigheter | inga (`uses-permission` saknas) | Bra: inget att motivera i Data safety |
| Backup | `user_data_backup/allow=true` i presetet (APK 0.29.4 hade `allowBackup=false`) | Se §5.2 |
| Storlek | APK ~42–44 MB | Långt under gränserna (§6) |
| Version | `version/code=96`, `version/name="0.30.30-test"` | versionCode måste öka för varje uppladdning – fungerar redan |

Slutsats: motorn (Godot 4.7.2) klarar redan target SDK 36, 64-bit och 16 KB. Det som saknas är
**Gradle/AAB, en riktig uppladdningsnyckel, ett slutligt paketnamn, ett utvecklarkonto och butikssidan med
policyformulären**, och för ett personligt konto **en sluten test med 12 testare i 14 dagar**.

## 2. AAB och Gradle-bygget i Godot

Google Play tar bara emot AAB för nya appar. Godot gör AAB bara med **Gradle Build** påslaget.

Steg (Godot-dokumentationen, "Exporting for Android" och "Gradle builds for Android", 4.7):

1. Projekt → **Install Android Build Template** (Gradle Build). Godot lägger ett Gradle-projekt i
   `res://android/build`. Mappen ska in i git (utom byggutdata – Godot lägger själv en `.gitignore`), och
   **måste installeras om när Godot uppgraderas**.
2. I Android-presetet: `gradle_build/use_gradle_build=true`, `gradle_build/export_format` = AAB.
   Min/target SDK kan sättas där (`gradle_build/min_sdk`, `gradle_build/target_sdk`); låt standard (36) stå.
3. Exportera till `export/rpg007.aab` i stället för `.apk`. För egna tester på telefonen kan man fortsätta
   med APK (samma preset med export_format APK, eller ett andra preset).

Verktyg som docs listar för 4.7: **OpenJDK 17** (finns: Temurin 17), Android SDK **Platform-Tools ≥ 35**,
**Build-Tools 35.0.1**, **Platform 35**, **Command-line Tools (latest)**, **CMake 3.10.2.4988404**,
**NDK r28b (28.1.13356709)**. Installerat i dag: build-tools 36.1.0, platforms android-36,
platform-tools, cmdline-tools – **saknas: build-tools 35.0.1, platform 35, NDK r28b, CMake**.
Docs säger "35" men templatet riktar sig mot 36; Gradle (Android Gradle Plugin) laddar oftast själv ned det
som saknas om licenserna är godkända. Säkrast är att installera exakt det docs listar med
`sdkmanager` (ingen Homebrew behövs):

```bash
SDK=~/Library/Android/sdk
$SDK/cmdline-tools/latest/bin/sdkmanager --sdk_root=$SDK \
  "build-tools;35.0.1" "platforms;android-35" "ndk;28.1.13356709" "cmake;3.10.2.4988404"
```

Första Gradle-bygget laddar ned Gradle och beroenden (några hundra MB, kräver nätet) och tar flera minuter;
senare byggen går fortare (Gradle-demonen ligger kvar i minnet – stoppa den med
`./gradlew --stop` i `android/build` eller `pkill -f GradleDaemon` efteråt för att spara värme och RAM).
NDK behövs normalt inte för att Godot ska bygga (motorns `.so` är förbyggd), men AGP kan vilja ha den för
att strippa symboler, och den behövs för egna plugins. **Antagande:** Gradle-bygget fungerar på macOS 13
Intel med JDK 17 – Gradle och AGP är Java och kräver inget nyare macOS; Android Studio behövs inte.

Exportflaggan i headless-läge är densamma: `godot --headless --path . --export-release Android export/rpg007.aab`.

## 3. Signering: Play App Signing och uppladdningsnyckeln

- Med **Play App Signing** (standard för nya appar) håller Google **appens signeringsnyckel**. Vi signerar
  bara AAB:n med en **uppladdningsnyckel**. Tappas uppladdningsnyckeln bort kan den återställas via Play
  Console (man skickar in en ny nyckels certifikat som PEM). Nya appar får dessutom "quantum-ready hybrid
  signing" automatiskt.
- Följd: en APK signerad med debug-nyckeln (det vi sideloadar i dag) och appen från Play har **olika
  signaturer**. Play-versionen kan inte installeras ovanpå den sideloadade – man måste avinstallera, och då
  försvinner sparfilerna i `user://` (om de inte återställs från backup). Säg det till testarna.

Skapa uppladdningsnyckeln (en gång, JDK 17:s `keytool`):

```bash
mkdir -p ~/Keys && chmod 700 ~/Keys
keytool -genkeypair -v -keystore ~/Keys/edsvurna-upload.keystore -storetype PKCS12 \
  -alias edsvurna-upload -keyalg RSA -keysize 4096 -validity 10000
```

Regler:

- **Aldrig i repot.** Lägg nyckeln utanför projektet (`~/Keys/`), och lägg ändå `*.keystore`, `*.jks`,
  `*.p12` och `export_credentials.cfg` i `.gitignore`. Godot sparar lösenord i `.godot/export_credentials.cfg`
  (redan ignorerad med `.godot/`), men använd hellre miljövariabler så att inget lösenord hamnar i någon fil.
- Godot kräver i dag att **keystore- och nyckellösenordet är samma**, och docs avråder från specialtecken:
  välj ett långt lösenord av bokstäver och siffror (minst 24 tecken).
- Spara lösenordet i macOS Nyckelring och läs det därifrån vid export:

```bash
security add-generic-password -a "$USER" -s edsvurna-upload -w   # frågar efter lösenordet
GODOT_ANDROID_KEYSTORE_RELEASE_PATH=$HOME/Keys/edsvurna-upload.keystore \
GODOT_ANDROID_KEYSTORE_RELEASE_USER=edsvurna-upload \
GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$(security find-generic-password -a "$USER" -s edsvurna-upload -w)" \
godot --headless --path . --export-release Android export/rpg007.aab
```

- **Säkerhetskopia:** nyckelfilen + lösenordet på två ställen utanför datorn (t.ex. lösenordshanterare och
  ett USB-minne i en låda). Kommandot i CLAUDE.md med debug-nyckeln kan stå kvar för testbyggen.

## 4. Utvecklarkontot

| | Personligt konto | Organisationskonto |
|---|---|---|
| Avgift | 25 USD, en gång (kreditkort, inte förbetalt) | samma |
| Identitet | juridiskt namn och adress (Google Payments-profilen), myndighets-ID kan krävas | **D-U-N-S-nummer** (kan ta upp till 30 dagar), organisationens namn/adress måste stämma med Dun & Bradstreet |
| Visas i butiken | namn, land, utvecklarens e-post; **full adress bara om appen tjänar pengar** | namn, adress, e-post, telefon |
| Testkrav | konton skapade efter 13 nov 2023: **sluten test med minst 12 testare som varit med oavbrutet i 14 dagar** innan produktion låses upp | inget sådant krav |
| Övrigt | måste verifiera en Android-enhet via Play Console-appen | – |

Rekommendation: **personligt konto** (gratis spel utan annonser och köp → adressen visas inte). Ett
organisationskonto lönar sig bara om det redan finns en firma (enskild firma kan också få D-U-N-S) och man
vill slippa 12×14-kravet. De 12 testarna måste vara Google-konton som går med i testet via en länk och
**stannar kvar 14 dagar i följd** – den som går ur och in börjar om. Skaffa 15–20 för marginal.

**EU:s Digital Services Act:** Play frågar om man är *trader* (näringsidkare) eller inte. En trader får
adress och telefon visade för EU-användare. **Antagande** (Play-sidan hittades inte, Chrome Web Store och
Apple gör så): ett gratis hobbyspel utan intäkter är "inte trader".

**Android developer verification** (nytt): från september 2026 i Brasilien, Indonesien, Singapore och
Thailand och från 2027 globalt måste appar på certifierade enheter komma från verifierade utvecklare, även
sideloadade APK:er. Appar på Play registreras automatiskt via Play Console. För sideload till testare
finns "limited distribution"-konton (upp till 20 enheter, gratis). Det påverkar vår nuvarande GitHub
Release-väg någon gång 2027 – ännu ett skäl att flytta testandet till Play.

## 5. Butikssidan och policyformulären

### 5.1 Grafik och text
- Appnamn ≤ 30 tecken ("De edsvurna"), kort beskrivning ≤ 80, lång ≤ 4000. Svenska som standardspråk,
  engelsk översättning valfri.
- Ikon 512×512 PNG (32-bit), feature graphic 1024×500, minst 2 skärmdumpar (helst 4–8, liggande 16:9
  går bra för spel). Skärmdumparna kan tas med `--screenshot` som vi redan gör.
- Kategori: Spel → Rollspel. Kontaktmejl (krävs, visas publikt).

### 5.2 Integritetspolicy och Data safety
- **Data safety-formuläret måste fyllas i även om appen inte samlar något**, och det kräver en länk till en
  **integritetspolicy** (gäller alla spår utom intern test). Policyn ska ligga på en publik, icke-PDF-sida –
  repot är privat, så använd t.ex. GitHub Pages i ett eget publikt repo eller Google Sites.
- Vad spelet gör: inga behörigheter, ingen nätverkstrafik, inga annonser, ingen analys, inga konton.
  Sparfilerna (`user://slot<n>/…`, `settings.cfg`, `macros.json`) stannar på telefonen. Att "samla" betyder
  i Googles mening att data **skickas från enheten** – det gör vi inte. Svar: **"Appen samlar inte in och
  delar inte någon användardata."**
- **allowBackup=true:** Androids Auto Backup lägger appens filer i användarens eget Google-konto, krypterat,
  och vi kan inte läsa dem. Googles FAQ säger att uppladdning till användarens egen molntjänst som appen
  inte når inte behöver deklareras. **Antagande:** det gäller Androids backup också (Googles vanliga
  tolkning i forum; ingen officiell rad hittades). Rekommendation: behåll backup på (sparfilerna följer med
  till en ny telefon, och de är små) och skriv en mening om det i integritetspolicyn. Vill man vara helt
  säker: `user_data_backup/allow=false` (så som APK 0.29.4 hade), men då försvinner sparningarna vid
  telefonbyte.
- Lägg till Godot-motorn i bedömningen: Godot skickar ingen telemetri. Om vi senare lägger till
  kraschrapporter, analys eller molnsparning måste formuläret och policyn uppdateras **innan** den versionen
  laddas upp.

### 5.3 Åldersklassning (IARC)
Ett frågeformulär i Play Console ger klassningar för alla regioner (PEGI i Sverige). Innehållet: fantasivåld
mot skelett, gastar, kultister och en fallen biskop; ingen blod-/sexdetalj, inga köp, ingen chatt, inget
spel om pengar. Ragnhild citerar bibelord respektfullt; fiender som kultister och häxor är fantasy, inte
ockultism som utövas. **Uppskattning:** PEGI 7–12 (fantasivåld mot människoliknande figurer brukar ge 12).
Svara sanningsenligt – fel svar kan ge borttagning. Motsvarar vår ton (`tone-fresh`): ondskan är fienden.

### 5.4 Målgrupp, annonser och övrigt
- Målgrupp: välj **13+ eller 16+** (inte under 13). Grupper under 13 drar in Families-policyn. Grupperna
  13–17 räknas i vissa länder som barn, men utan annonser och datainsamling är det inget problem. Undvik
  barnslig grafik i butiksbilderna (Google kan annars tycka att appen riktar sig till barn).
- Annonser: **Nej**. App access: alla funktioner nås utan inloggning. Government/news/health: nej.
- Licenser: Quaternius och Kenney är CC0 (fritt även kommersiellt). Gå igenom `ASSETS_LICENSE.md` och
  illustrationernas ursprung (VD:ns ark) en gång innan publicering, och lägg en krediteringsrad i spelet.

## 6. Storlek

- AAB-gränser: **basmodul 500 MB** komprimerad nedladdning (Play har höjt den från 200 MB; CLAUDE.md:s
  "200 MB bas" är gammal), asset pack 1,5 GB styck, 4 GB totalt för install-time. Över 200 MB får användare
  på mobildata en (icke-blockerande) varning – det är den praktiska gränsen.
- APK-uppladdning (gamla sättet) har 100 MB – irrelevant när vi går över till AAB.
- Vi ligger på ~44 MB. **Play Asset Delivery behövs inte** förrän spelet närmar sig 200 MB.
- AAB:n ger mindre nedladdningar än APK:n (Play delar upp per enhet), men med bara arm64 och få
  språk blir vinsten liten.

## 7. Paketnamnet

`applicationId` går **aldrig** att ändra efter första uppladdningen, och samma namn kan aldrig återanvändas
ens om appen tas bort. Det syns i butikens URL (`play.google.com/store/apps/details?id=…`). `prototype` ska
inte stå där.

Förslag (välj ett innan första uppladdning, även till intern test):

1. **`se.edsvurna.spel`** – kort, svenskt, kräver inte att man äger domänen (men skaffar man
   `edsvurna.se` senare stämmer det). *Rekommenderas.*
2. `se.bjornjansson.edsvurna` – om fler spel ska komma under samma namn.
3. `io.github.broklyn777.edsvurna` – knutet till GitHub-kontot.

Följder av bytet: Android ser det som en ny app. Testarnas sparfiler under `se.rpg007.prototype` följer inte
med automatiskt (olika `user://`). Byt därför namnet samtidigt som Play-testandet börjar, säg till testarna,
och behåll gärna det gamla namnet för sideloadade utvecklingsbyggen (två presets) så att båda kan ligga
installerade samtidigt. Byt också `config/name` till "De edsvurna".

## 8. Testspår och pre-launch report

| Spår | Vem | Granskning | Används till |
|---|---|---|---|
| **Intern test** | upp till 100 namngivna testare (e-postlista) | ingen/snabb, tillgänglig på minuter | snabba byggen till oss själva; behöver inte Data safety |
| **Sluten test** | inbjudna via e-postlista eller Google-grupp | granskas (första gången kan ta dagar) | **12 testare × 14 dagar**-kravet; vänner och familj |
| **Öppen test** | alla som hittar sidan | granskas | publik beta (kräver produktionsåtkomst för personliga konton) |
| **Produktion** | alla | granskas, ofta 1–7 dagar för en ny app | lansering |

**Pre-launch report:** Play installerar varje AAB som laddas upp till ett testspår på riktiga enheter i
Firebase Test Lab och låter en robot trycka runt i några minuter. Den rapporterar krascher, ANR,
prestanda, tillgänglighet och säkerhet. För ett Godot-spel ser roboten bara en yta, men krascher vid start
och på olika GPU:er (GL Compatibility) fångas – värdefullt eftersom vi bara testat på en telefon.

Att testa på surfplatta: appar som riktar sig mot Android 16 får sin låsta orientering och storlek
ignorerad på stora skärmar (≥ 600 dp). Vårt spel är liggande, så det borde gå bra, men testa en
surfplatta/vikbar i emulatorn eller pre-launch-rapporten. Kantlös visning (edge-to-edge) tvingas sedan API
35 – `immersive_mode=true` täcker det, men kontrollera kameraurtag.

## 9. Stegordning med tidsuppskattning

**Kan göras nu (utan att något blir permanent):**

| # | Steg | Tid |
|---|---|---|
| 1 | Bestäm slutligt paketnamn och visningsnamn (§7) | 15 min samtal |
| 2 | Skapa uppladdningsnyckeln, Nyckelringen, säkerhetskopia (§3) | 30 min |
| 3 | `sdkmanager`: build-tools 35.0.1, platform 35, NDK r28b, CMake (§2) | 30 min (~1,5 GB nedladdning) |
| 4 | Installera Android Build Template, slå på Gradle, AAB-preset; första bygget; kontrollera AAB:n med `bundletool dump config` (PAGE_ALIGNMENT_16K) | 1–3 h, mest väntan; värmetungt – en gång, sedan sällan |
| 5 | Skriv integritetspolicyn (svensk + engelsk) och lägg den på en publik sida | 1 h |
| 6 | Butikstext, ikon 512, feature graphic, 6–8 skärmdumpar | 3–5 h |
| 7 | Licensgenomgång och krediteringsrad | 1 h |
| 8 | Samla 15–20 testare med Google-konto (Android) | kalendertid, börja tidigt |

**Senare (när spelet ska ut till fler):**

| # | Steg | Tid |
|---|---|---|
| 9 | Skapa personligt utvecklarkonto, betala 25 USD, verifiera ID och Android-enhet | 1 h + 1–7 dagar verifiering |
| 10 | Skapa appen, fyll i Data safety, IARC, målgrupp, annonser, app access, DSA-status | 2 h |
| 11 | Första AAB till **intern test** (namnet blir permanent här) | 30 min |
| 12 | **Sluten test** med ≥ 12 testare, 14 dagar i följd; samla synpunkter, ladda upp fixar | 14+ dagar |
| 13 | Ansök om produktionsåtkomst (frågor om testet) | 30 min + granskning, upp till ~7 dagar |
| 14 | Produktion (gärna stegvis utrullning) | 1–7 dagars granskning |

Totalt: ungefär **2–3 dagars arbete** och **3–5 veckors kalendertid**, styrt av 14-dagarstestet och
granskningarna.

## 10. Risker för vår verktygskedja

- **Gamla macOS 13 på Intel-iMac 2017.** Gradle/AGP och JDK 17 fungerar, men framtida AGP-versioner kan
  kräva JDK 21; Temurin 21 finns för Intel-macOS och kan installeras manuellt på samma sätt. Android Studio
  behövs inte. Homebrew undviks som förut.
- **Värme och tid.** Gradle-bygget är tyngre än dagens exporter (demonen + kompilering). Bygg AAB bara när
  något ska till Play; fortsätt med APK utan Gradle för vardagstester (andra preset). Stoppa Gradle-demonen
  efteråt.
- **Templatet följer Godot-versionen.** Vid uppgradering av Godot måste `android/build` installeras om, och
  SDK-kraven kan ändras.
- **Target SDK-kravet stiger varje augusti** (2027: troligen API 37). Det betyder en Godot-uppgradering per år
  ungefär – annars får uppdateringar inte släppas. En gammal Mac som inte kör nyare Godot vore ett hot;
  Godot 4.x kräver i dag macOS 10.13+ så det är inte akut.
- **Nyckeln.** Tappas uppladdningsnyckeln går den att återställa, men det tar tid; läcker den är det värre.
  Därför ingen nyckel eller lösenord i repot eller i CLAUDE.md.
- **Sparfiler vid byte.** Nytt paketnamn och ny signatur betyder att testarna börjar om (§3, §7).
- **Grafikdrivrutiner.** GL Compatibility på okända telefoner – pre-launch-rapporten och sluten test är
  första gången vi ser fler än en enhet.
- **Policyer ändras.** Läs om §4–5 innan kontot skapas och innan produktion.

## Källor

- Target API: <https://developer.android.com/google/play/requirements/target-sdk>
- 16 KB-sidor: <https://developer.android.com/guide/practices/page-sizes>
- Godot 16 KB-stöd (PR #106358, NDK r28b, i 4.5): <https://forum.godotengine.org/t/godot-and-google-play-policy-warning-about-16-kb-memory-page-size/120934>,
  <https://github.com/godotengine/godot/issues/106313>
- Godot, export till Android (4.7): <https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html>
- Godot, Gradle-bygge: <https://docs.godotengine.org/en/stable/tutorials/export/android_gradle_build.html>
- Godot 4.7 target SDK 36 som standard (forum): <https://forum.godotengine.org/t/how-to-target-latest-android-sdk/142631>
- Play App Signing: <https://support.google.com/googleplay/android-developer/answer/9842756>
- Registrering och avgift: <https://support.google.com/googleplay/android-developer/answer/6112435>
- Personligt vs organisation, D-U-N-S: <https://support.google.com/googleplay/android-developer/answer/13628312>
- Testkrav för nya personliga konton: <https://support.google.com/googleplay/android-developer/answer/14151465>
- Android developer verification: <https://developer.android.com/developer-verification>
- Data safety: <https://support.google.com/googleplay/android-developer/answer/10787469>
- Målgrupp och Families: <https://support.google.com/googleplay/android-developer/answer/9867159>
- Storleksgränser: <https://support.google.com/googleplay/android-developer/answer/9859372>
- DSA trader-status (Chrome Web Store, närmaste Google-motsvarighet): <https://developer.chrome.com/docs/webstore/program-policies/trader-verification-faq>
