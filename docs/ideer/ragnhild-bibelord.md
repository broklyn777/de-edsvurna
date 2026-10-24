# Ragnhilds bibelord – kontroll (2026-10-21, ny genomgång 2026-10-24)

Regel (CLAUDE.md): Ragnhild citerar bibelord **endast ur 1917 års kyrkobibel**, ordagrant och kontrollerade, och aldrig
för att förlöjliga tron. Citaten står inom »…«. Gudsnamnet skrivs HERREN i versaler där 1917 gör det (i Gamla
testamentet, där grundtexten har Guds namn).

**Källa:** Wikisource, *Bibeln 1917*. Texten hämtades 2026-10-24 som wikitext (`action=raw`) och jämfördes tecken för tecken
med replikerna; korshänvisningarna i slutet av versen (">Ps. 37,16 …") hör inte till texten. Sidorna:
[Psaltaren](https://sv.wikisource.org/wiki/Bibeln_1917/Psaltaren) ·
[Ordspråksboken](https://sv.wikisource.org/wiki/Bibeln_1917/Ordspr%C3%A5ksboken) ·
[Predikaren](https://sv.wikisource.org/wiki/Bibeln_1917/Predikaren) ·
[Matteusevangeliet](https://sv.wikisource.org/wiki/Bibeln_1917/Matteusevangeliet) ·
[Romarbrevet](https://sv.wikisource.org/wiki/Bibeln_1917/Romarbrevet) ·
[Första Korintherbrevet](https://sv.wikisource.org/wiki/Bibeln_1917/F%C3%B6rsta_Korintherbrevet) ·
[Första Thessalonikerbrevet](https://sv.wikisource.org/wiki/Bibeln_1917/F%C3%B6rsta_Thessalonikerbrevet)

Tillåtna avvikelser: ett utdrag (ett led av versen), stor bokstav i början och punkt i slutet när citatet slutar mitt i en
mening, och rubriken "En psalm av David" utelämnad. Inget annat.

## Rättat 2026-10-24

| Ställe | Var | Före | Efter |
|---|---|---|---|
| Ps. 121:2 | `barks.ragnhild.rescue.2` | »Min hjälp kommer från Herren, … | »Min hjälp kommer från HERREN, … |
| Ps. 23:1 | `barks.ragnhild.campfire.2` | »Herren är min herde, … | »HERREN är min herde, … |
| Ps. 121:7 | `barks.ragnhild.alone.2` | »Herren skall bevara dig … | »HERREN skall bevara dig … |
| Pred. 3:1 | `inn.ragnhild.bored.0` | ”Allting har sin tid.” | »Allting har sin tid.« |
| Ps. 121:8 | `inn.ragnhild.welcome.0` | ”HERREN skall bevara … tid.” | »HERREN skall bevara … tid.« |

Ordalydelsen stämde i alla 20 citat. Felen var bara versalerna i HERREN (tre ställen) och citattecknen (två ställen).
`cave.2` (Ps. 119:105), som textgranskningen också nämnde, stämmer och har inget gudsnamn.

## Alla Ragnhilds bibelord i `data/dialog.json`

Platserna:
- `barks.ragnhild.<tillfälle>.2` (med `ref`)
- `inn.ragnhild.*` (med `ref`)
- `chronicle.lines.N` (talare Ragnhild, med `ref`)
- samtalen `pairs` (`pair_ragnhild_*`, utan `ref`; stället står här)

| Ställe | 1917 års text (Wikisource) | Var | Hos Ragnhild |
|---|---|---|---|
| Ps. 23:1 | En psalm av David. HERREN är min herde, mig skall intet fattas, | `barks.ragnhild.campfire.2` | utan rubriken, punkt i slutet (rättat: HERREN) |
| Ps. 119:105 | Ditt ord är mina fötters lykta och ett ljus på min stig. | `barks.ragnhild.cave.2`, `chronicle.lines.83` | ordagrant |
| Ps. 119:114 | Du är mitt beskärm och min sköld; jag hoppas på ditt ord. | `barks.ragnhild.boss.2` | ordagrant |
| Ps. 121:2 | Min hjälp kommer från HERREN, som har gjort himmel och jord. | `barks.ragnhild.rescue.2` | ordagrant (rättat: HERREN) |
| Ps. 121:7 | HERREN skall bevara dig för allt ont, han skall bevara din själ. | `barks.ragnhild.alone.2` | ordagrant (rättat: HERREN) |
| Ps. 121:8 | HERREN skall bevara din utgång och din ingång, från nu och till evig tid. | `inn.ragnhild.welcome.0` | ordagrant (rättat: »…«) |
| Ords. 16:8 | Bättre är något litet med rättfärdighet än stor vinning med orätt. | `barks.ragnhild.treasure.2` | ordagrant |
| Ords. 16:18 | Stolthet går före undergång, och högmod går före fall. | `barks.ragnhild.elite.2`, `chronicle.lines.55` | ordagrant |
| Ords. 27:2 | Må en annan berömma dig, och icke din egen mun, främmande, och icke dina egna läppar. | `pairs` `pair_ragnhild_sefir` | första ledet, punkt |
| Ords. 27:12 | Den kloke ser faran och söker skydd; de fåkunniga löpa åstad och få plikta därför. | `barks.ragnhild.back.2` | första ledet, punkt |
| Pred. 3:1 | Allting har sin tid, och vart företag under himmelen har sin stund. | `inn.ragnhild.bored.0` | första ledet, punkt (rättat: »…«) |
| Pred. 3:7 | Riva sönder har sin tid, och sy ihop har sin tid. Tiga har sin tid, och tala har sin tid. | `pairs` `pair_ragnhild_eira` | andra meningen |
| Matt. 5:4 | Saliga äro de som sörja, ty de skola bliva tröstade. | `barks.ragnhild.fallen.2`, `chronicle.lines.5` | ordagrant |
| Matt. 5:7 | Saliga äro de barmhärtiga, ty dem skall vederfaras barmhärtighet. | `pairs` `pair_ragnhild_alva` | ordagrant |
| Rom. 12:12 | Varen glada i hoppet, tåliga i bedrövelsen, uthålliga i bönen. | `barks.ragnhild.hard_fight.2`, `chronicle.lines.51` | ordagrant |
| Rom. 12:13 | Tagen del i de heligas behov. Varen angelägna om att bevisa gästvänlighet. | `barks.ragnhild.home.2`, `chronicle.lines.113` | andra meningen |
| Rom. 12:16 | … utan hållen eder till det som är ringa. Hållen icke eder själva för kloka. | `pairs` `pair_ragnhild_solveig` | sista meningen |
| 1 Kor. 14:40 | Men låten allt tillgå på höviskt sätt och med ordning. | `pairs` `pair_ragnhild_tove` | ordagrant |
| 1 Tess. 5:16 | Varen alltid glada. | `barks.ragnhild.stairs.2` | ordagrant |
| 1 Tess. 5:21 | men pröven allt, behållen vad gott är, | `pairs` `pair_ragnhild_brokk` | stor bokstav, punkt |

Inte inbyggt än: hemkomsten (`home` visas inte i grottan).
Förslagen i `docs/ideer/chat-vardshuset-och-sok.md` har kvar ”…” och är källmaterial; spelets text står i `dialog.json`.
