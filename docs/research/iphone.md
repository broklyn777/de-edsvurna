# Vägen till iPhone

Research 2026-10-24 (gren `research-iphone`, från `test-0.30`). Ingen Godot kördes; källor längst ned.
Frågan: hur når "De edsvurna" (Godot 4.7.2, GL Compatibility, Android först) App Store när utvecklaren har en
iMac 2017 med macOS 13 Ventura?

## Kort svar

- **iMacen kan inte bygga för App Store, och kommer aldrig att kunna.** Sedan 28 april 2026 måste allt som laddas upp
  till App Store Connect byggas med **Xcode 26 eller senare och iOS 26-SDK**. Xcode 26 kräver macOS Sequoia 15.6
  (26.4 och senare kräver Tahoe 26.2). Ventura räcker till Xcode **15.2** (iOS 17.2-SDK). Xcode 27 (september 2026)
  kräver Tahoe 26.6 **och en Mac med Apple silicon** – Intel stöds inte alls. Om Apple följer sitt mönster blir
  Xcode 27 / iOS 27-SDK kravet våren 2027 (vår gissning, inte meddelat).
- OpenCore Legacy Patcher (ny macOS på gammal Intel-Mac) är ingen väg: det hjälper möjligen till Xcode 26, men inte
  till Xcode 27 och framåt, och det är ett säkerhets- och tidsprojekt i sig.
- **Rekommendation:** bygg i molnet. GitHub Actions med macOS-runner (eller Codemagic) exporterar Godot headless,
  bygger med Xcode, signerar med App Store Connect API-nyckel och skickar till TestFlight. Ingen Mac behövs i
  vardagen. Kostnad: 99 USD/år till Apple plus i praktiken 0–15 USD/månad i byggminuter. En begagnad Mac mini M1/M2
  (ca 3 000–5 000 kr) är alternativet om man vill felsöka i Xcode själv.
- **En iPhone att prova på behövs ändå** (TestFlight). iOS-simulatorn kräver en Mac och kör bara Compatibility – vilket
  råkar vara vår renderare, men den säger lite om prestanda.

## 1. Apples krav (oktober 2026)

| | Krav | Källa |
|---|---|---|
| Uppladdning till App Store Connect | Xcode 26+ och iOS 26-SDK sedan 28 april 2026 | Apple, "Upcoming requirements" |
| Xcode 26.0–26.3 | macOS Sequoia 15.6+ | Apple, Xcode system requirements |
| Xcode 26.4–26.6 | macOS Tahoe 26.2+ | samma |
| Xcode 27, 27.1, 27.2 RC | macOS Tahoe 26.6+, bara Apple silicon | samma; Xcode 27-releaseanteckningar |
| Senaste Xcode på Ventura 13.5 | Xcode 15.2 (iOS 17.2-SDK) | samma |
| Lägsta iOS att stödja | Vårt val (`application/min_ios_version`); SDK-kravet styr bara vad man bygger *mot* | Godot, Apple |

Följder för oss:

- Även lokal felsökning på en ny iPhone med iOS 26/27 kräver en Xcode som känner till den iOS-versionen, alltså
  inte Xcode 15.2. iMacen kan som mest köra Godot-editorn och exportera Xcode-projektet (se §3).
- **Apple Developer Program:** 99 USD/år (i Sverige debiteras kronor; ett forum-inlägg nämner 995 kr, kontrollera i
  appen Apple Developer). Utan förnyelse försvinner appen ur butiken. TestFlight ingår.
- **EU: handlarstatus (DSA).** Sedan 17 feb 2025 måste varje utvecklare i App Store Connect ange om hen är
  *trader* (näringsidkare) eller inte. En handlare får namn, adress, telefon och e-post publicerade på
  produktsidan i EU. Säljer vi spelet eller tar betalt i appen är vi rimligen handlare – välj då en
  företagsadress/enskild firma i stället för hemadressen. Ett gratis hobbyspel kan anges som icke-handlare.
- **Åldersgräns:** Apples nya frågeformulär (sedan 2025; 4+, 9+, 13+, 16+, 18+, per land) måste vara ifyllt för att
  få skicka uppdateringar. Vi har fantasivåld mot monster, ingen blod-/gorefokus, ingen chatt, inga köp: troligen
  9+ eller 13+. Ragnhilds bibelord och religiösa teman är inget problem så länge de inte hånar (och det gör de inte,
  se CLAUDE.md).
- **Integritet ("privacy nutrition label") och privacy manifest:** Vi samlar inget – inga konton, ingen analys,
  ingen reklam, sparfiler bara i `user://`. Etiketten blir "Data Not Collected". Godots iOS-export har egna fält
  för privacy manifest (`privacy/*` i exportförinställningen: `tracking_enabled`, `*_access_reasons` för
  UserDefaults, filtidsstämplar, disk, uppstartstid, samt `collected_data/*`). Fyll i skälen för de API:er motorn
  använder (filtidsstämplar och troligen UserDefaults) – annars nekas uppladdningen sedan maj 2024. Exakt vilka
  koder Godot 4.7 behöver får provas fram vid första uppladdningen (Apple mejlar en lista om något saknas).
- **Granskning (App Review) för spel:** vanliga stopp är krascher vid start, platshållartext, länkar till
  Android/Google Play, saknad iPad-layout (om man markerar iPad-stöd), knappar som inte gör något och "copycat"
  (riktlinje 4.1). Vi har egna namn och egen värld, inspirerad av Siralim men inte en kopia – nämn inte Siralim i
  butikstexten. Testversioner via TestFlight till externa testare granskas också (lättare, oftast inom ett dygn).

## 2. Godot 4.7 på iOS

- **Export:** Godot skriver ett Xcode-projekt (`.xcodeproj` + `.pck`) och kan, på en Mac med Xcode, bygga
  `.xcarchive`/`.ipa` direkt. `application/export_project_only=true` ger bara projektet, som sedan byggs med
  `xcodebuild` eller fastlane. Kräver Team ID (10 tecken) och Bundle ID (t.ex. `se.rpg007.edsvurna`; Godots
  projektnamn måste skilja sig från det exporterade namnet). Provisioning-profilens UUID kan ges via
  `GODOT_IOS_PROVISIONING_PROFILE_UUID_RELEASE` – passar CI.
- **Renderare:** Compatibility (vår) kör OpenGL ES 3.0 på iOS. Apple har markerat OpenGL ES som föråldrat sedan
  iOS 12 men det finns kvar i iOS 26/27 och Godot-spel med Compatibility släpps fortfarande. Risken är att Apple en
  dag tar bort det; då är vägen Mobile-renderaren, som på Apple kör **Metal** (eget Metal-gränssnitt sedan Godot
  4.4; Metal-exporter kräver som standard A12 Bionic eller senare, sedan 4.5.2). Simulatorn kör bara Compatibility.
  - Rekommendation: behåll Compatibility nu (samma bild som på Android, ett enda utseende att granska). Gör ett
    provbygge med Mobile/Metal en gång när molnbygget fungerar, för att veta vad det skulle kosta att byta.
  - ANGLE: Godot har prövat ANGLE-Metal på macOS och backat (4.2.1); ingen ANGLE på iOS att räkna med.
  - Våra shaders (pergament, fördärvet som bläck, dimman) är GLSL ES 3.0-kompatibla eftersom de redan kör på
    Android med samma renderare – det är den stora fördelen med att stanna på Compatibility.
- **Texturer:** `import_etc2_astc=true` är redan på. iPhone (A8+) stöder ASTC, så inget nytt behövs.
- **Notch, Dynamic Island och hemindikator:** spelet saknar idag kod för säker yta (inget
  `DisplayServer.get_display_safe_area()` i `scripts/` eller `src/`). I liggande läge äter ön/notchen ca 45–60
  punkter på ena sidan och hemindikatorn ca 20 punkter nedtill. Knappar längst ut till vänster/höger (‹ PROFILER,
  GE UPP, 1×/Auto, kortraden) kan hamna under ön. Lösning: en liten `SafeArea`-hjälpare som läser
  `get_display_safe_area()` och lägger marginaler på de yttre behållarna; bakgrunder och 3D ritas ändå hela vägen
  ut. Det hjälper också Android-telefoner med hålkamera – **kan göras nu**.
- **Upplösning och bildförhållande:** `canvas_items`/`expand` klarar iPhones 19,5:9 och iPads 4:3. Bestäm om vi
  stöder iPad från start (fler skärmdumpar och granskningskrav) – förslag: bara iPhone först.
- **Orientering:** liggande (orientation=4, sensor landscape) fungerar; iOS-exporten har egna fält för tillåtna
  orienteringar.
- **Prestanda:** iPhones GPU:er är generellt starkare än mellanklass-Android med samma GLES3-väg. Spara-ofta
  (`run.cfg` efter varje rum) är bra: iOS dödar bakgrundsappar utan varning. Kontrollera att musik pausas vid
  `NOTIFICATION_APPLICATION_PAUSED` och att ljudsessionen respekterar tyst-knappen (Godots standard är
  "ambient"-liknande; prova på telefonen).
- **Ljud:** `.ogg` och `.wav` fungerar. Telefonens tyst-läge: Godot har projektinställningen
  `audio/general/ios/session_category`; "Ambient" följer tyst-knappen, vilket spelare väntar sig.
- **Text:** `NameEntry` öppnar tangentbordet på iOS också; kontrollera att fältet inte döljs bakom tangentbordet i
  liggande läge (`DisplayServer.virtual_keyboard_get_height()`).
- **Licenser:** Quaternius/Kenney (CC0) och egna ljud är fria för App Store. Godot (MIT) kräver att licenstexten
  finns med någonstans i spelet (t.ex. i handboken eller inställningarna) – gäller redan Android.

## 3. Var bygger vi? Alternativen

| Alternativ | Kostnad (ca) | För | Emot |
|---|---|---|---|
| **GitHub Actions, macOS-runner** | Privat repo: 2 000 gratisminuter/mån men macOS räknas ×10 = 200 macOS-min. Därefter 0,062 USD/min (standard M1, 3–4 kärnor). Ett bygge ~10–20 min → ~1 USD/bygge, 10–15 gratis byggen/mån | Repot ligger redan på GitHub; `gh` finns; Xcode-versioner förinstallerade och uppdaterade; inget att administrera | Felsöka utan att se Xcode-fönstret; spärr på 0 USD måste höjas för att bygga mer |
| **Codemagic** | 500 gratisminuter Mac mini M2/mån (1 parallellt bygge), sedan 0,095 USD/min (M2), 0,114 (M4) | Mest gratisminuter; inbyggd App Store Connect-signering och TestFlight-uppladdning; stöd för "andra" motorer via skript | Ännu ett konto och en tjänst med våra nycklar |
| **MacinCloud** | Pay-as-you-go ca 1 USD/h; delad ca 25–29 USD/mån; dedikerad M2 99 USD/mån | Riktigt skrivbord via fjärrskrivbord – man ser Xcode | Segt över fjärrskrivbord, klagomål på debitering; man måste själv hålla Xcode aktuell |
| **AWS EC2 Mac** | Dedikerad värd, minst 24 h per gång, ca 1,1–1,3 USD/h (M-serie) → minst ~30 USD per tillfälle | Fullt kontrollerad | Krångligt och dyrt för en person; 24 h-minimum |
| **Scaleway Mac mini** | Minst 24 h per gång (M1 var ca 0,10 €/h vid lanseringen; M4 dyrare, kolla priset) | Billigast för en heldag i Xcode | 24 h-minimum, fjärrskrivbord |
| **Begagnad Mac mini M1/M2** | 3 000–5 000 kr engångs | Lokalt Xcode, simulator, kabeldebug, Instruments för prestanda | Maskin att sköta; M1 tappar stöd om ~4–6 år |

**Rekommendation:** GitHub Actions för vardagens byggen (eller Codemagic om gratisminuterna behövs), och vid behov
en dag på Scaleway/MacinCloud för den första manuella felsökningen i Xcode. Köp en Mac mini först om iPhone blir
en riktig plattform (lansering), inte för att komma igång.

## 4. Molnbygget i detalj (GitHub Actions)

Flödet, steg för steg i ett arbetsflöde (`.github/workflows/ios.yml`, körs manuellt eller på taggar):

1. `runs-on: macos-15` (eller `macos-26` när den finns som standard) och välj Xcode:
   `sudo xcode-select -s /Applications/Xcode_26.x.app` (kraven ovan).
2. Hämta Godot 4.7.2 för macOS (universal, `.zip` från godotengine.org/GitHub releases) och exportmallarna
   (`Godot_v4.7.2-stable_export_templates.tpz`) till
   `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`. Cacha dem (actions/cache) så att varje
   bygge inte laddar ned ~1 GB.
3. `godot --headless --path . --export-release "iOS" build/ios/rpg007.xcodeproj` med en iOS-förinställning i
   `export_presets.cfg` som har `application/export_project_only=true`. (Godot importerar resurserna första gången;
   cacha `.godot/imported` för att spara minuter.)
4. Signering utan Mac hemma, två vägar:
   - **Enklast: App Store Connect API-nyckel + automatisk signering.** Skapa en nyckel (.p8, Issuer ID, Key ID) i App
     Store Connect, lägg den som GitHub-hemlighet. `xcodebuild -allowProvisioningUpdates
     -authenticationKeyPath … -authenticationKeyID … -authenticationKeyIssuerID …` skapar certifikat och profil
     själv. Fastlane `app_store_connect_api_key` gör samma sak.
   - **Fastlane match:** certifikat och profiler krypterade i ett privat git-repo; `match appstore --readonly` i CI.
     Bra om flera maskiner ska bygga; för oss överkurs.
5. Bygga: `xcodebuild archive -project … -scheme … -archivePath build/rpg007.xcarchive` och
   `xcodebuild -exportArchive -exportOptionsPlist ExportOptions.plist` (method `app-store-connect`), eller
   fastlane `gym`.
6. Skicka: `xcrun altool --upload-app` / fastlane `pilot` (TestFlight) med samma API-nyckel. Byggnumret räknas upp
   automatiskt (`version/code` på Android motsvaras av `CFBundleVersion`; använd `github.run_number`).
7. Spara `.ipa` och loggar som artefakter.

Allt utom Apple-kontot kan förberedas och provas utan att betala: steg 1–3 (export till Xcode-projekt och ett
osignerat simulatorbygge) går på GitHubs gratisminuter. GodotCon Amsterdam 2026 hade ett föredrag om just detta
(GitHub Actions + fastlane match/gym/pilot för Godot utan egen Mac) – titta på det innan arbetsflödet skrivs.

Obs: Godots dokumentation säger att iOS-export görs från en Mac. Om Godot på Linux/iMac kan skriva Xcode-projektet
med `export_project_only` har vi inte provat; det spelar mindre roll när exporten ändå sker på macOS-runnern.

## 5. Stegplan med tid och kostnad

| # | Steg | Tid (ca) | Kostnad | Kan göras nu? |
|---|---|---|---|---|
| 0 | Säker yta (`SafeArea`-hjälpare) och kontroll av tangentbord, paus och ljud vid appbyte – gynnar Android också | 1 session | 0 | **Ja** |
| 1 | iOS-förinställning i `export_presets.cfg` (Bundle ID, ikoner 1024², startskärm, orientering, privacy-fält, `export_project_only`) utan hemligheter; Team ID via miljövariabel/CI | 1–2 h | 0 | **Ja** (Team ID senare) |
| 2 | CI för Android först: tester + APK på GitHub Actions (Linux, billigt). Samma mönster för hemligheter (keystore som secret, `GODOT_ANDROID_KEYSTORE_RELEASE_*` finns redan som miljövariabler) | 1 session | 0 (Linux-minuter) | **Ja** |
| 3 | macOS-jobb: hämta Godot, exportera Xcode-projekt, bygga osignerat för simulatorn | 1 session | ~0 (gratisminuter) | **Ja** |
| 4 | Apple Developer Program, handlarstatus, App ID, API-nyckel | 1–2 dagar (Apples verifiering kan ta upp till 48 h; för enskild firma behövs ev. D-U-N-S) | 99 USD/år | När vi bestämt oss |
| 5 | Signerat bygge → TestFlight intern testning på egen iPhone | 1–2 sessioner | några USD i minuter | efter 4 |
| 6 | Prova på telefonen: säker yta, prestanda, ljud, spara/återuppta, tangentbord; åtgärda | 1–3 sessioner | – | efter 5 |
| 7 | Butikssidan: skärmdumpar 6,9" (1320×2868 liggande motsvarande), beskrivning, åldersfrågor, integritetsetikett, integritetspolicy-URL (krävs även om vi inte samlar något – en enkel sida räcker) | 1 session | 0 | text kan skrivas nu |
| 8 | Extern TestFlight (upp till 10 000 testare, lätt granskning) och sedan App Review | dagar | – | efter 6 |

Total kontant kostnad första året: **99 USD + 0–15 USD/mån** i byggminuter. Med Mac mini: + 3 000–5 000 kr engångs.

## 6. Vad vi kan förbereda från Android-arbetet nu

- **Inga hemligheter i repot.** Android-nyckeln skickas redan via miljövariabler; gör likadant med Team ID,
  API-nyckel och profil-UUID. `export_presets.cfg` innehåller i dag inga lösenord – håll det så.
- **CI på GitHub Actions** för tester och APK (Linux): samma arbetsflöde får sedan ett macOS-jobb. Det ger också
  APK:er som GitHub Release automatiskt (CLAUDE.md nämner redan Releases för stora APK:er).
- **Säker yta och appens livscykel** (paus, ljud, spara) – samma problem på Android med hålkamera.
- **Ikoner och startskärm** i full upplösning (1024×1024 utan genomskinlighet för App Store).
- **Integritetspolicy** (en kort sida: "spelet samlar inga data") – behövs också för Google Play.
- **Plattformsoberoende kod:** inga `OS.get_name() == "Android"`-grenar hittades i `scripts/`/`src/`; fortsätt så.
- **Butikstexter och åldersfrågor** på svenska och engelska, gemensamma med Google Play.
- **Renderaren:** stanna på Compatibility; undvik shader-knep som bara fungerar i Vulkan/Mobile.

## Öppna frågor till VD

1. Säljs spelet (handlarstatus, publicerad adress) eller är det gratis/hobby först?
2. iPhone bara, eller iPad också från start?
3. Molnbygge (rekommenderat) eller en begagnad Mac mini?
4. Finns en iPhone att testa på (vilken modell och iOS-version)?

## Källor

- Apple, SDK minimum requirements (Xcode 26 / iOS 26-SDK från 28 april 2026):
  https://developer.apple.com/news/upcoming-requirements/
- Apple, Xcode system requirements (macOS per Xcode-version, 14.x–27.2 RC):
  https://developer.apple.com/xcode/system-requirements/
- Apple Developer Forums, "Xcode 27 for Intel Macs" (citat ur releaseanteckningarna: bara Apple silicon):
  https://developer.apple.com/forums/thread/829619
- Blake Crosley, "Xcode 27 Is Out: Requirements, Targets, and What Broke": https://blakecrosley.com/blog/xcode-27-release
- Expo, App Store Connect minimum SDK 26: https://expo.dev/blog/app-store-connect-minimum-sdk-26
- Godot 4.7-dokumentationen, Exporting for iOS: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_ios.html
- Godot, EditorExportPlatformIOS (privacy-fält, `export_project_only`, `min_ios_version`):
  https://docs.godotengine.org/en/stable/classes/class_editorexportplatformios.html
- Godot, Overview of renderers: https://docs.godotengine.org/en/stable/tutorials/rendering/renderers.html
- Godot 4.5.2 RC 1 (Metal-export kräver A12 som standard): https://godotengine.org/article/release-candidate-godot-4-5-2-rc-1/
- Godot 4.4 dev 1 (Metal-gränssnittet): https://godotengine.org/article/dev-snapshot-godot-4-4-dev-1/
- Godot 4.2.1 (ANGLE-Metal på macOS backat): https://godotengine.org/article/maintenance-release-godot-4-2-1
- GodotCon Amsterdam 2026, iOS-byggen utan Mac med GitHub Actions och fastlane:
  https://talks.godotengine.org/godotcon-ams-2026/talk/VGASKF/
- GitHub, Actions runner pricing: https://docs.github.com/en/billing/reference/actions-runner-pricing
- GitHub, How use of GitHub Actions is measured (2 000 min, macOS ×10):
  https://docs.github.com/en/billing/concepts/product-billing/github-actions
- Codemagic, pricing: https://codemagic.io/pricing/
- Green Mini, jämförelser med MacinCloud och AWS EC2 Mac (konkurrentens sidor, priser ca juni 2026):
  https://www.greenmini.nl/compare/macincloud-alternative/ och https://www.greenmini.nl/compare/aws-ec2-mac-alternative/
- AWS, EC2 Mac FAQ (24 h minimum): https://aws.amazon.com/ec2/instance-types/mac/faqs/
- TechCrunch, appar utan handlarstatus togs bort ur EU:s App Store (feb 2025):
  https://techcrunch.com/2025/02/18/apple-purges-apps-without-contact-info-from-eu-app-store-as-dsa-deadline-hits
- 9to5Mac, Apples nya åldersgränser (juli 2025): https://9to5mac.com/2025/07/24/apple-notifies-developers-of-new-app-store-age-rating-system/
- Expo, Apple privacy manifest (required reason APIs): https://docs.expo.dev/guides/apple-privacy/
- Apple Developer Forums, avgift i kronor (995 kr, år oklart): https://developer.apple.com/forums/thread/756477

Osäkert och värt att kontrollera när det blir dags: Scaleways och AWS aktuella timpriser för M4, Apples pris i
kronor, exakt vilka privacy-skäl Godot 4.7 behöver, och om/när Apple kräver Xcode 27 för uppladdning.
