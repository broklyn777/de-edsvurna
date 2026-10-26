# Byggvägar – underlag ur datan (0.30.46)

Genererat ur `data/` (heroes, traits, enemies, encounters, artifacts, materials, oaths, abilities). Texterna är datans egna. Grupperingen efter användning är mekanisk: den bygger på troféns kombinationstagg (`combo.creates`) eller på effekten, och säger vad delen främst gör, inte vem den är tänkt för. Som i Siralim finns inget färdighetsträd: en hjälte specialiseras av sin egen egenskap, sin trofé, sin artefakt (typ, material, trick, troféplats, Nether Stone) och Paladinens kall.

Platser per hjälte: egen egenskap, en trofé (byts vid lägereld eller hemma), en artefakt med nivå 1–10 (stat-platser på nivå 2/5/9, trick-platser 3/7, troféplats 6, Nether-plats 10).

## 1. Följeslagarna

### Paladinen – Edsvuren (ledare)

Grundstats: Health 90, Attack 9,5, Intelligence 9,5, Defense 5, Speed 10. Personlighet från start: trofast.
- Egen egenskap: kallet (se avsnitt 6).
- Egen egenskap **Domens kall**: När en annan i sällskapet tar direkt skada från en fiende slår Paladinen tillbaka för 40 % (en gång per tur).
- Anfall: Svärdshugg
- Förmåga **Rättfärdigt slag** (8 Charges): Helig attack (160 %). Slår 50 % hårdare mot en Förblindad fiende.
- Förmåga **Helig sköld** (5 Charges): En allierad blir Beskyddad: tar 50 % mindre skada i 3 turer.

### Imma – Bågskytt (skada)

Grundstats: Health 62, Attack 10,6, Intelligence 8, Defense 1,8, Speed 18. Personlighet från start: rastlos.
- Egen egenskap **Fingerfärdig**: När Imma träffar en fiende som har en buff stjäl hon den och ger den till den svagaste i sällskapet.
- Anfall: Pil
- Förmåga **Trickpil** (6 Charges): En hullingpil: 80 % skada och målet Blöder (30 % av sitt liv per tur) i 2 turer.
- Förmåga **Rökpil** (5 Charges): Röken gör alla fiender Förblindade i 2 turer, och Imma blir Smidig.
- Förmåga **Gnistpil** (8 Charges): En liten besvärjelse i pilspetsen: eldskada (100 % av Intelligence, Liten).

### Brokk – Dvärgkrigare (tank)

Grundstats: Health 115, Attack 7,8, Intelligence 7,7, Defense 6, Speed 7. Personlighet från start: envis.
- Egen egenskap **Stenhård**: När Brokk försvarar sig får hela sällskapet Styrka: nästa anfall gör 30 % mer skada.
- Anfall: Yxhugg
- Förmåga **Stenmur** (5 Charges): Brokk försvarar sig och hela sällskapet tar 25 % mindre skada till hans nästa tur.
- Förmåga **Krigsrop** (5 Charges): Hela sällskapet får Styrka: nästa anfall gör 30 % mer skada.
- Makroförslag när hen ansluter: Brokk kan skydda de andra: "Om någon allierad har liv under 50 %: Provocera."

### Syster Alva – Präst (helare)

Grundstats: Health 70, Attack 6,5, Intelligence 6,5, Defense 2,5, Speed 11. Personlighet från start: klok.
- Egen egenskap **Välsignande hand**: När Alva helar en allierad får målet Välsignelse: nästa anfall gör 25 % mer skada och blir Heligt.
- Anfall: Ljusstråle
- Förmåga **Helande ljus** (5 Charges): Tar bort en debuff från en allierad och helar den (230 % av Intelligence).
- Förmåga **Läkande hand** (3 Charges): Målet får Läkning: helas 25 % av sitt liv i början av sina tre nästa turer.
- Förmåga **Ljusets dom** (8 Charges): Helig besvärjelse (150 %).
- Makroförslag när hen ansluter: Alva lär dig ett villkor – hela den som har lågt liv: "Om någon allierad har liv under 50 %: Helande ljus på den." Raden används bara när villkoret stämmer.

### Jägaren Eira – Jägare (skada)

Grundstats: Health 65, Attack 9, Intelligence 9, Defense 2, Speed 14. Personlighet från start: rastlos.
- Egen egenskap **Jägarinstinkt**: När Eira träffar ett märkt mål skjuter hon en pil till för 50 % (en gång per tur).
- Anfall: Pil
- Förmåga **Märk byte** (8 Charges): Märker målet i 3 turer (tar 20 % mer skada), snärjer det längst ned på tidslinjen och skjuter för 60 %.
- Förmåga **Pilregn** (6 Charges): Pilar mot alla fiender (60 %).
- Makroförslag när hen ansluter: Eira märker sitt byte: "Om någon fiende saknar Märkt: Märk byte."

### Solveig – Eldmagiker (skada)

Grundstats: Health 60, Attack 8,3, Intelligence 8,3, Defense 1,5, Speed 12. Personlighet från start: drommande.
- Egen egenskap **Glödande själ**: Solveigs direkta eldträffar har 50 % chans att sätta fyr på målet (30 % av hennes Intelligence per tur i 2 turer).
- Anfall: Eldstöt
- Förmåga **Eldvåg** (6 Charges): Eldskada på alla fiender (70 %).
- Förmåga **Eldklot** (5 Charges): Stor eldbesvärjelse (200 %).
- Makroförslag när hen ansluter: Solveig bränner grupper: "Om alla fiender lever: Eldvåg."

### Ronja Falkvind – Falkenerare (kontroll)

Grundstats: Health 65, Attack 9,2, Intelligence 6,9, Defense 2,5, Speed 15. Personlighet från start: snabbfotad.
- Egen egenskap **Falkens vakt**: När en fiende väljer ett mål i sällskapet dyker Stormvinge ned: fienden flyttas ett steg ned på tidslinjen och blir Märkt (en gång per tur).
- Anfall: Klohugg
- Förmåga **Dykattack** (8 Charges): Falken dyker: 120 % skada, 50 % mer mot Märkta.
- Förmåga **Spejarflykt** (5 Charges): Alla fiender blir Märkta (tar 20 % mer skada) i 2 turer.
- Förmåga **Vingskugga** (6 Charges): En allierad blir Smidig (25 % extra undvikande) i 2 turer.

### Lirien Silversträng – Bard (stöd)

Grundstats: Health 62, Attack 6,9, Intelligence 9,8, Defense 2, Speed 13. Personlighet från start: drommande.
- Egen egenskap **Allsång**: När Lirien ger en allierad en buff med en förmåga får alla andra i sällskapet samma buff i 1 tur. Buffar från en egenskap (en trofé, kallet eller artefaktens egna kast) sprids inte.
- Anfall: Dissonans
- Förmåga **Stridssång** (6 Charges): En allierad får Styrka (nästa anfall +30 %) i 3 turer.
- Förmåga **Vaggvisa** (5 Charges): En fiende somnar i högst 2 turer (vaknar av skada).
- Förmåga **Hjältens ballad** (4 Charges): En allierad flyttas överst på tidslinjen och får nästa tur.
- Makroförslag när hen ansluter: Lirien sjunger: "Om en allierad saknar Styrka: Stridssång."

### Broder Tove – Munk (tank)

Grundstats: Health 75, Attack 9,8, Intelligence 4,6, Defense 2,5, Speed 16. Personlighet från start: lattfotad.
- Egen egenskap **Spegelhand**: När Tove undviker ett anfall kontrar han för 100 % och blir 10 % snabbare resten av striden.
- Anfall: Handflata
- Förmåga **Vindsteg** (6 Charges): Tove blir Smidig i 3 turer och provocerar.
- Förmåga **Tryckpunkt** (8 Charges): Anfall 100 %; målet blir Hånat (kan inte anfalla) i 1 tur.
- Förmåga **Stilla vatten** (6 Charges): Tove försvarar sig och blir av med alla debuffar.

### Hulda Mossrot – Druid (stöd)

Grundstats: Health 70, Attack 5,7, Intelligence 10,3, Defense 3, Speed 8. Personlighet från start: klok.
- Egen egenskap **Rotverk**: Huldas förmågor på allierade ger målet ett Rotskott (högst 3). När bäraren tar en direkt träff slår varje Rotskott angriparen för 15 % av Huldas Intelligence.
- Anfall: Tornpiska
- Förmåga **Snärjande rötter** (6 Charges): En fiende blir Snärjd: fast längst ned på tidslinjen i 2 turer.
- Förmåga **Lövskydd** (6 Charges): En allierad får en Barriär (100 % av Huldas Intelligence).
- Förmåga **Svampring** (5 Charges): Alla fiender blir Förgiftade (30 % av Huldas Attack per tur) i 3 turer.
- Makroförslag när hen ansluter: Hulda skyddar: "Om någon allierad har liv under 50 %: Lövskydd."

### Ragnhild Ljusdom – Domare (skada)

Grundstats: Health 80, Attack 8,6, Intelligence 9,2, Defense 4,5, Speed 9. Personlighet från start: stadig.
- Egen egenskap **Sanningens ljus**: När en fiende helas eller får en buff bränner ljuset den (Helig skada, 50 % av Ragnhilds Intelligence), och med nåd helas den svagaste i sällskapet med en fjärdedel av det (12 %).
- Anfall: Klubbslag
- Förmåga **Brännmärke** (6 Charges): Fienden blir Fördärvad (helning skadar i stället) och Sårbar i 2 turer.
- Förmåga **Skingra lögnen** (6 Charges): Tar bort alla buffar från en fiende.
- Förmåga **Ljusvåg** (5 Charges): Helig skada (70 %) på alla fiender.

### Sefir av Sanden – Svärdsdansare (skada)

Grundstats: Health 60, Attack 9,5, Intelligence 4, Defense 1,5, Speed 17. Personlighet från start: impulsiv.
- Egen egenskap **Bladvirvel**: En kritisk träff flyttar Sefir överst på tidslinjen (en gång per tur).
- Anfall: Kroksabel
- Förmåga **Dansande stål** (8 Charges): Två hugg à 60 % mot samma mål.
- Förmåga **Vindens steg** (5 Charges): Sefir flyttas överst på tidslinjen och blir Vildsint (25 % extra krit) i 2 turer.
- Förmåga **Tusen snitt** (3 Charges): 30 % skada på alla fiender, som börjar Blöda i 2 turer.

### Torun Bergsbrytare – Bergsbrytare (tank)

Grundstats: Health 120, Attack 10, Intelligence 6, Defense 6,5, Speed 11. Personlighet från start: grundlig.
- Egen egenskap **Inte färdigt än**: Står Torun beredd (Stå beredd) när en fiende släpper en varslad attack eller helar, avbryter hon det: handlingen blir inte av och fiendens tur går åt. En boss eller Resistent fiende tappar inte laddningen, den skjuts upp en tur. Inte när Torun är Tystad, sover eller är frusen, och inte laddningar som bara bryts på annat sätt (Midnatt).
- Anfall: Släggslag
- Förmåga **Stå beredd** (6 Charges): Torun försvarar sig, drar fiendernas anfall till sig och håller släggan lyft till sin nästa tur. Släpper en fiende en varslad attack eller helar sig under tiden, avbryter hon det (Inte färdigt än). Nedkylning 3 turer.
- Förmåga **Kilslag** (8 Charges): Ett tungt slag (150 %). Mot en Vacklande fiende – en laddning som Tystad eller skada bröt – eller ett troll med Svedd hud slår det 50 % hårdare.
- Förmåga **Stötta upp** (5 Charges): En allierad får en Barriär (8 % av Toruns Health).
- Makroförslag när hen ansluter: Torun kan avbryta: "Om någon fiende laddar och slår om högst 1 tur: Stå beredd."

## 2. Troféer efter användning

Format: namn [sällsynthet] – källa: text. Bosstroféer kräver tre segrar mot samma boss; väktarnas troféer kommer efter segrar mot väktaren.

### Helning, HoT och grupphelning (11)

- **Diakonens stola** [vanlig] – Fördärvad diakon: När bäraren helar någon får målet Läkning i 2 turer.
- **Gravprästens radband** [vanlig] – Gravpräst: Bärarens Heliga skada helar den svagaste i sällskapet för 25 % av skadan.
- **Mosskappan** [vanlig] – Mossrygg: I början av bärarens tur helas bäraren för 6 % av sitt max liv.
- **Väktarens hjälm** [vanlig] – Gravväktare: När bäraren Försvarar eller Provocerar helas den svagaste i sällskapet för 140 % av bärarens Defense.
- **Den rena källan** [elit] – Ärkediakon (sällsynt elitvariant av Fördärvad diakon): Bärarens helningar tar bort en debuff från målet.
- **Den rivna slukväven** [elit] – Slukaren (elit): Bärarens anfall mot en Snärjd fiende gör 60 % mer skada och helar bäraren med 30 %. Snärjningen släpper.
- **Den släckta lyktan** [elit] – Gravväckaren (elit): En gång per strid: när någon i sällskapet faller väcks hen med 30 % liv.
- **Den återtända ljusstaken** [elit] – Gravabbot (sällsynt elitvariant av Gravpräst): I början av bärarens tur helas hela sällskapet för 8 % av bärarens max liv.
- **Edsbrytarens fall** [elit] – Edsbrytare (sällsynt elitvariant av Fallen riddare): Om bäraren har använt en förmåga i striden återuppstår hen en gång med 50 % liv.
- **Silverskärvan** [elit] – Silverspegeln (sällsynt elitvariant av Spegelvakten): Första besvärjelsen som skadar bäraren i striden studsar tillbaka: bäraren får livet tillbaka och kastaren tar lika mycket (indirekt).
- **Abbedissans nyckel** [boss] – Den fördärvade abbedissan (miniboss): När bäraren helar någon renas målet från alla debuffar, men bärarens helningar är 20 % svagare.

### Tank: försvar, Barriär, provokation (11)

- **Den rivna slöjan** [vanlig] – Gast: Bäraren undviker 20 % av attacker, och blir Smidig (25 % extra undvikande i 3 turer) varje gång hen undviker.
- **Den tystade skramlan** [vanlig] – Skramlaren: Efter en direkt attack mot bäraren blir hen Defensiv i 1 tur (en gång per tur).
- **Det brustna bönebandet** [vanlig] – Kultist: I början av bärarens tur får den svagaste i sällskapet en Barriär för 60 % av bärarens Intelligence.
- **Det släckta irrblosset** [vanlig] – Irrbloss: Bäraren undviker attacker så ofta det går (taket för undvikande, 75 %) tills hen har agerat första gången.
- **Kistspiken** [vanlig] – Kistbärare: När en allierad faller får sällskapet en Barriär för 8 % av bärarens max liv.
- **Den brutna fogdestaven** [elit] – Blodfogden (sällsynt elitvariant av Blodsvuren): Första gången i striden som bäraren hamnar under 50 % liv får hen en Barriär för 25 % av sitt max liv.
- **Förmannens nyckelknippa** [elit] – Kultens förman (elit): I början av bärarens tur blir den svagaste i sällskapet Beskyddad i 1 tur.
- **Sista vaktens sköld** [elit] – Likbärare (sällsynt elitvariant av Kistbärare): Första gången en allierad faller blir bäraren Provocerande i 2 turer.
- **Bergakungens kluvna krona** [boss] – Bergakungen (boss): Bäraren tar 40 % mindre skada när fienderna gör samma sorts handling två gånger i rad.
- **Biskopens mitra** [boss] – Den fallne biskopen (boss): Bäraren kan inte skadas så länge minst två andra i sällskapet lever, men hela sällskapet gör 25 % mindre skada.
- **Den vandrande kronan** [boss] – väktaren Abbedissans kör: Bäraren börjar striden med kronan: den som bär den tar 30 % mindre skada men gör 15 % mindre. Efter tre av bärarens turer, eller när hen faller, går kronan till den allierade med lägst liv.

### Skada (24)

- **Blodsvurens kniv** [vanlig] – Blodsvuren: Bäraren gör 6 % mer skada för varje tiondel liv hen saknar (högst +30 %).
- **Den fallnes klinga** [vanlig] – Fallen riddare: Medan bäraren försvarar sig slår hen tillbaka mot varje attack för 50 %.
- **Den kapade bågsträngen** [vanlig] – Skelettbågskytt: Bärarens attacker mot märkta mål är alltid kritiska.
- **Den krossade benkronan** [vanlig] – Benfursten (boss): Bärarens följdanfall räknas som Heliga besvärjelser, men bärarens direkta besvärjelser gör 20 % mindre skada.
- **Den slocknade glöden** [vanlig] – Glödskelett: När någon i sällskapet helas får bäraren en Glöd (högst 5). Bärarens nästa förmåga förbrukar dem: +15 % skada per Glöd.
- **Den trasiga fanan** [vanlig] – Fanbäraren: Sällskapet gör 8 % mer skada medan bäraren lever.
- **Det andra hugget** [vanlig] – Skelettkrigare: Efter en kritisk direkt attack gör bäraren ett följdanfall för 40 % (en gång per tur).
- **Krossarens klubba** [vanlig] – Stenkrossaren: Bärarens anfall mot en fiende som Försvarar gör +50 % skada.
- **Spegelskölden** [vanlig] – Spegelvakten: Den som skadar bäraren med en besvärjelse tar 60 % tillbaka (indirekt).
- **Stålet ur vaggan** [vanlig] – Bortbytingen: När en fiende skadar någon annan i sällskapet som har under 50 % liv slår bäraren tillbaka för 60 % (en gång per tur).
- **Askmolnet** [elit] – Askspindeln (sällsynt elitvariant av Dammspindel): Bärarens anfall gör 25 % mer skada mot Förblindade fiender.
- **Askurnan** [elit] – Askbärare (sällsynt elitvariant av Glödskelett): När bäraren träffar med en direkt attack tar alla andra fiender 30 % av skadan (indirekt).
- **Brospännet** [elit] – Brom, broarnas väktare (miniboss): Bärarens anfall mot en fiende som Provocerar gör +40 % skada.
- **Det brutna gisslet** [elit] – Självplågare (sällsynt elitvariant av Botgörare): Bäraren gör 10 % mer skada för varje direkt träff hen har tagit i striden.
- **Det upprepade slaget** [elit] – Ockultist (sällsynt elitvariant av Kultist): Bärarens förmågor gör 20 % mer skada för varje gång samma förmåga redan använts i striden.
- **Grimmens brustna halsband** [elit] – Kyrkogrimmen (elit): När en fiende skadar någon annan i sällskapet än bäraren med en direkt träff biter bäraren den fienden för 40 % (en gång per tur).
- **Kaparens första hugg** [elit] – Benkapten (sällsynt elitvariant av Skelettkrigare): Bärarens första Anfall i striden gör 200 % mer skada.
- **Klapperstenen** [elit] – Benklappret (sällsynt elitvariant av Skramlaren): Efter en direkt attack mot bäraren blir hen Defensiv i 1 tur och anfallaren tar 20 % av skadan tillbaka (en gång per tur).
- **Lansspetsen** [elit] – Den svarta lansen (elit): Bärarens första Anfall i striden struntar i Defense.
- **Sidenslingan** [elit] – Silkessnärjaren (sällsynt elitvariant av Snärjspindel): Bäraren gör 25 % mer skada mot Snärjda fiender.
- **Skrivarens penna** [elit] – Benskrivaren (elit): Medan bäraren lever räknas sällskapets träffar aldrig som upprepningar (Antecknat), och bäraren gör 15 % mer skada med en handling hen inte gjorde förra turen.
- **Smaragdgiftet** [elit] – Smaragdtanden (sällsynt elitvariant av Gifttandsspindel): Bärarens gift gör 50 % mer skada på Snärjda fiender.
- **Snabbt tag** [elit] – Benjägare (sällsynt elitvariant av Skelettbågskytt): När bäraren träffar med en direkt attack har hen 40 % chans att anfalla samma mål igen (en gång per tur).
- **Den krossade svarta kronan** [boss] – Den svärtade Benfursten (boss): När någon i sällskapet faller sveper bäraren fienderna med Benstorm (gratis), men bärarens helningar är 25 % svagare.

### Kontroll och debuffar (20)

- **Bödelns huva** [vanlig] – Botgörare: Bärarens kritiska träffar gör målet Sårbart: +50 % skada i 2 turer.
- **Dammpungen** [vanlig] – Dammspindel: Bärarens anfall mot en Förgiftad fiende förblindar den till efter dess nästa tur.
- **Den brutna gravspaden** [vanlig] – Likätare: Fiender som bäraren fäller kan inte väckas. Bäraren helas 10 % av sitt max liv när hen fäller en fiende.
- **Den brutna trollstaven** [vanlig] – Häxa: Bärarens direkta besvärjelser har 50 % chans att tysta målet i 1 tur (fiender kan då bara anfalla).
- **Den möglade klingan** [vanlig] – Mögelskelett: Bärarens direkta attacker har 30 % chans att förgifta målet i 3 turer.
- **Den tömda giftflaskan** [vanlig] – Gifttandsspindel: När en fiende blir Snärjd förgiftar bäraren den i 3 turer.
- **Hullingtråden** [vanlig] – Hullingspindel: En Förblindad fiende som skadar någon i sällskapet börjar blöda (1 tur).
- **Snärjtråden** [vanlig] – Snärjspindel: Bärarens första anfall i striden snärjer målet (längst ned på tidslinjen).
- **Blodtornet** [elit] – Blodtaggen (sällsynt elitvariant av Hullingspindel): En Snärjd fiende som anfaller bäraren börjar blöda (1 tur).
- **Den krossade lyktan** [elit] – Lyktgubbe (sällsynt elitvariant av Irrbloss): Bärarens första träff i striden förblindar målet i 1 tur.
- **Den skingrade dimman** [elit] – Gravdimman (elit): Bäraren kan inte sövas (inte heller Dimsömn). Bärarens första besvärjelse i striden söver målet i 1 tur.
- **Dvalnätet** [elit] – Sömnvävaren (elit): Bärarens anfall mot en Snärjd fiende söver den (tills den tar skada).
- **Gråluvans sjal** [elit] – Trollmor Gråluva (elit): Var tredje gång bäraren agerar somnar en slumpad fiende i 1 tur.
- **Inkvisitorns sigill** [elit] – Inkvisitorn (elit): Fiender som använder samma förmåga två gånger i rad blir Tystade i 1 tur.
- **Saltad jord** [elit] – Gravfogde (sällsynt elitvariant av Gravväktare): När bäraren Försvarar eller Provocerar förlorar alla fiender 20 % Defense i 3 turer.
- **Smittans väg** [elit] – Sporfursten (sällsynt elitvariant av Mögelskelett): När en förgiftad fiende faller förgiftas en annan fiende.
- **Den lösta strypknuten** [boss] – Strypvävaren (miniboss): I början av bärarens tur snärjs fienden som står överst på tidslinjen, men bäraren börjar striden längst ned.
- **Domstolens klubba** [boss] – väktaren Inkvisitorns domstol: Bärarens direkta träffar ger målet en stapel Skuld (20 % mindre helning per stapel, högst tre). Bäraren gör 25 % mer skada mot den som har Skuld, men 15 % mindre mot andra.
- **Midnattsklockans kläpp** [boss] – väktaren Midnattsklockan: Var tredje gång bäraren agerar ljuder kläppen: alla fiender som laddar en varslad attack avbryts och vacklar. Men bäraren tar 15 % mer skada.
- **Moderns silke** [boss] – Vävmodern (boss): Fiender som sliter sig loss ur Snärjd förgiftas i 3 turer, men sällskapets anfall gör 15 % mindre skada.

### Stöd och buffar (12)

- **Den kluvna stenen** [vanlig] – Avundsjätten: När en fiende får en buff får bäraren samma buff (en gång per tur).
- **Grytskärvan** [vanlig] – Grytmodern: När en fiende helas får bäraren +10 % Attack (högst 3 gånger per strid).
- **Springarens steg** [vanlig] – Benspringare: Bäraren börjar striden Smidig i 2 turer.
- **Asketens rem** [elit] – Asketen (elit): Bäraren får +6 % Defense i början av varje egen tur (högst 5 gånger).
- **Den sprängda bojan** [elit] – Gravgnagaren (sällsynt elitvariant av Likätare): När en fiende faller får bäraren +8 % Attack för resten av striden (högst 3 gånger).
- **Förvarningen** [elit] – Klagekvinnan (sällsynt elitvariant av Gast): Bäraren börjar alltid striden överst på tidslinjen.
- **Häroldens horn** [elit] – Härolden (sällsynt elitvariant av Fanbäraren): När bäraren Provocerar blir sällskapet Vildsint i 1 tur.
- **Häxmästarinnans brutna spira** [elit] – Häxmästarinna (sällsynt elitvariant av Häxa): Bärarens förmågor har 30 % chans att kastas en gång till, utan Charge.
- **Kolossens tålamod** [elit] – Benkolossen (elit): Bäraren får +8 % Attack i början av varje egen tur (högst 5 gånger).
- **Vargens språng** [elit] – Benvarg (sällsynt elitvariant av Benspringare): Bäraren börjar striden överst på tidslinjen.
- **Klockrepet** [boss] – Klockaren (miniboss): När fienderna flyttas överst på tidslinjen följer bäraren med (en gång per tur), men bäraren börjar striden längst ned.
- **Rådets sigill** [boss] – väktaren Kistornas råd: När en allierad faller ärver bäraren hens troféegenskap resten av striden. Men bäraren tar emot 20 % mindre helning.

## 3. Artefakttyper

En per hjälte, smids hos Smeden. Typen ger en stat och avgör när artefaktens förmåga (en av hjältens egna) kastas gratis. Varje nivå stärker stat, chans, material och trick med 10 %.

- **Svärd** (`sword`): +5 % Attack; 25 % chans vid Anfall.
- **Stav** (`staff`): +5 % Intelligence; 25 % chans vid Förmåga.
- **Sköld** (`shield`): +1 Defense; 50 % chans vid Försvara.
- **Hjälm** (`helm`): +5 % Health; 50 % chans vid Provocera.
- **Stövlar** (`boots`): +1 Speed; 15 % chans i början av turen.

Mekanisk koppling: Sköld (vid Försvar) och Hjälm (vid Provocera) passar den som försvarar eller provocerar; Stav (vid Förmåga) den som kastar förmågor, t.ex. helningar; Svärd (vid Anfall) den som anfaller; Stövlar (i början av turen) alla.

## 4. Material: bärnsten, trick och Nether Stones

### Bärnsten (stat-platser, 5 per plats, förstörs när den tas ut)

- **Röd bärnsten** (`amber_red`, Amber (Attack)): Attack ×1.0
- **Blå bärnsten** (`amber_blue`, Amber (Intelligence)): Intelligence ×1.0
- **Grön bärnsten** (`amber_green`, Amber (Health)): Health ×1.0
- **Järngrå bärnsten** (`amber_grey`, Amber (Defense)): Defense ×1.0
- **Gul bärnsten** (`amber_yellow`, Amber (Speed)): Speed ×1.0
- **Orange bärnsten** (`amber_orange`, Amber (Attack/Health)): Attack ×0.6, Health ×0.6
- **Violett bärnsten** (`amber_violet`, Amber (Intelligence/Speed)): Intelligence ×0.6, Speed ×0.6
- **Turkos bärnsten** (`amber_teal`, Amber (Health/Defense)): Health ×0.6, Defense ×0.6
- **Rosa bärnsten** (`amber_rose`, Amber (Intelligence/Health)): Intelligence ×0.6, Health ×0.6
- **Bronsfärgad bärnsten** (`amber_bronze`, Amber (Attack/Defense)): Attack ×0.6, Defense ×0.6

Intelligence styr både helning (Int × förmågans power) och besvärjelsers skada; Health och Defense bär en tank; Speed ger tidigare turer, krit och undvikande.

### Trick (trick-platser, förstörs när de tas ut)

*Tank: försvar, Barriär, provokation*
- **Rustningsskrot** (`armor_scrap`): Bäraren tar 8 % mindre skada.
- **Hal sten** (`slippery_stone`): 7 % högre chans att undvika anfall.

*Skada*
- **Brynsten** (`whetstone`): Anfall gör 12 % mer skada.
- **Taggsten** (`jagged_rock`): 8 % högre chans till kritiska anfall.
- **Arkant sigill** (`arcane_sigil`): Besvärjelser gör 12 % mer skada.

*Kontroll och debuffar*
- **Sårbarhetens kuriosa** (`curio_vulnerable`): 12 % chans att göra målet Sårbart vid en direkt träff.

*Stöd och buffar*
- **Styrkans skiffer** (`slate_inspired`): 15 % chans att få Styrka vid en direkt träff.

### Nether Stones

Slumpade, 1–4 egenskaper efter sällsynthet: stat i procent, ett trick eller en troféegenskap. Går tillbaka till förrådet när de tas ut. Hittas bara på det djupaste djupet man nått. Sällsyntheter: Vanlig (1 egenskap), Magisk (2 egenskaper), Sällsynt (3 egenskaper), Legendarisk (4 egenskaper).

## 5. Kallen och deras perks

Kärnan verkar alltid för hela sällskapet; perks kostar 1–3 perk-poäng vid Kallets altare och återställs gratis. En besegrad boss låser upp en lånad perk från ett annat kall. Användningen i hakparentes är mekanisk (se ovan).

### Domens kall (Siralims Paladin)

Idé: Slå tillbaka när sällskapet träffas.
- Kärna: När en annan i sällskapet tar direkt skada från en fiende slår Paladinen tillbaka för 40 % (en gång per tur). [Skada]
- **Vrede** (1 p, 3 nivåer): Domens kall slår 50 % hårdare för en allierad som försvarar sig. [Skada]
- **Iver** (1 p, 3 nivåer): Domens kall slår 50 % hårdare för en allierad som provocerar. [Skada]
- **Domslut** (1 p): När någon i sällskapet stupar tar alla fiender Helig skada (40 % av Paladinens Attack, indirekt). [Skada]
- **Klockan klämtar** (2 p): När Domens kall slår tillbaka har Paladinen 15 % chans att kasta Helig smäll gratis mot samma fiende. [Stöd och buffar]
- **Räkenskap** (2 p): När någon i sällskapet provocerar anfaller hen en slumpad fiende. [Skada]
- **Ljusets hand** (3 p): När Domens kall slår tillbaka helas hela sällskapet för 10 % av skadan. [Helning]

### Gryningens kall (Siralims Cleric)

Idé: Helning blir Barriärer och buffar.
- Kärna: När någon i sällskapet helas får hen en Barriär lika stor som helningen. Paladinens direkta träffar helar den svagaste i sällskapet för 30 % av skadan. [Tank]
- **Smörjelse** (1 p): Den som helas får Välsignelse: nästa anfall gör 25 % mer skada och blir Heligt. [Stöd och buffar]
- **Helig makt** (1 p, 3 nivåer): Sällskapet gör 15 % mer skada per buff de har (Barriär räknas). [Skada]
- **Ledljus** (2 p): När striden börjar får hela sällskapet en Barriär för 15 % av sitt liv. [Tank]
- **Uppenbarelse** (2 p): I början av Paladinens tur: 30 % chans att väcka en stupad allierad med 30 % liv. [Helning]
- **Större helning** (2 p, 2 nivåer): All helning i sällskapet är 50 % starkare. [Helning]

### Väktarens kall (Siralims Siegemaster)

Idé: Försvara, provocera och slå tillbaka med Defense.
- Kärna: När någon i sällskapet träffas av ett anfall eller en besvärjelse slår hen tillbaka för 35 % av sin Defense (indirekt skada). [Skada]
- **Titanisk vrede** (1 p, 2 nivåer): Sällskapet gör 50 % mer skada mot fiender som försvarar sig eller provocerar. [Skada]
- **I formation** (2 p): Hela sällskapet börjar striden försvarande. [Tank]
- **Bästa försvaret** (2 p, 2 nivåer): Direkta anfall gör extra skada lika med 30 % av anfallarens Defense. [Skada]
- **Vila upp** (2 p): När någon i sällskapet försvarar sig får hen tillbaka en Charge på en förmåga. [Stöd och buffar]
- **Krigsmaskin** (2 p): När någon i sällskapet provocerar försvarar hen sig också. [Tank]

