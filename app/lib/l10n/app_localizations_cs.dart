// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Czech (`cs`).
class AppLocalizationsCs extends AppLocalizations {
  AppLocalizationsCs([String locale = 'cs']) : super(locale);

  @override
  String get appTitle => 'Astro';

  @override
  String get navProfiles => 'Profily';

  @override
  String get navPeople => 'Osobnosti';

  @override
  String get navAsk => 'Zeptej se';

  @override
  String get navGlossary => 'Slovníček';

  @override
  String get navSettings => 'Nastavení';

  @override
  String get profilesEmpty => 'Zatím žádný profil. Přidej první horoskop.';

  @override
  String get addProfile => 'Přidat profil';

  @override
  String get editProfile => 'Upravit profil';

  @override
  String get deleteProfile => 'Smazat profil';

  @override
  String deleteProfileConfirm(Object name) {
    return 'Smazat profil $name? Nejde to vrátit.';
  }

  @override
  String get cancel => 'Zrušit';

  @override
  String get save => 'Uložit';

  @override
  String get delete => 'Smazat';

  @override
  String get ok => 'Rozumím';

  @override
  String get fieldName => 'Jméno';

  @override
  String get fieldDate => 'Datum narození';

  @override
  String get fieldTime => 'Čas narození';

  @override
  String get timeUnknown => 'Čas neznám';

  @override
  String get fieldPlace => 'Místo narození';

  @override
  String get placeSearchHint => 'Hledej obec nebo město';

  @override
  String get manualCoords => 'Zadat souřadnice ručně';

  @override
  String get fieldLat => 'Zeměpisná šířka (°, sever +)';

  @override
  String get fieldLon => 'Zeměpisná délka (°, východ +)';

  @override
  String get fieldZone => 'Časové pásmo (IANA)';

  @override
  String get timeBasis => 'Jak číst čas';

  @override
  String get basisZone => 'Místní čas';

  @override
  String get basisUt => 'Zadávám UT';

  @override
  String get basisLmt => 'Místní střední čas';

  @override
  String get calendar => 'Kalendář';

  @override
  String get calGregorian => 'gregoriánský';

  @override
  String get calJulian => 'juliánský';

  @override
  String get houseSystemField => 'Systém domů';

  @override
  String get houseSystemAuto => 'Automaticky podle šířky';

  @override
  String get dstAmbiguous =>
      'Tento čas při změně letního času nastal dvakrát nebo vůbec. Zkontroluj ho, případně zadej UT.';

  @override
  String get lmtNotice =>
      'Čas před zavedením pásmového času: počítá se místní střední čas místa narození.';

  @override
  String get tabOverview => 'Přehled';

  @override
  String get tabTables => 'Tabulky';

  @override
  String get tabReading => 'Výklad';

  @override
  String get tabTransits => 'Tranzity';

  @override
  String get positions => 'Pozice planet';

  @override
  String get houses => 'Domy';

  @override
  String get aspects => 'Aspekty';

  @override
  String get planetStates => 'Stav planet';

  @override
  String get compareSystems => 'Srovnat systémy domů';

  @override
  String get houseSize => 'velikost';

  @override
  String get changesHouse => 'mění dům';

  @override
  String get noHouses =>
      'Čas narození neznámý: horoskop je bez domů, ascendentu a MC.';

  @override
  String get moonUncertain =>
      'Měsíc ten den mění znamení; bez času není jisté, ve kterém je.';

  @override
  String get polarHouses => 'Tento systém domů není na této šířce definovaný.';

  @override
  String get unequalHousesWarning =>
      'Na této šířce vycházejí domy Placida velmi nestejné. Zvaž Porphyry.';

  @override
  String get readingBySections => 'Po oddílech';

  @override
  String get readingByThemes => 'Podle témat';

  @override
  String get sectionSigns => 'Planety ve znameních';

  @override
  String get sectionHouses => 'Planety v domech';

  @override
  String get sectionAspects => 'Aspekty';

  @override
  String get sectionCusps => 'Znamení na hrotech domů';

  @override
  String get sectionEmphasis => 'Přemíra a nedostatek';

  @override
  String get patterns => 'Obrazce aspektů';

  @override
  String get noPatterns => 'V horoskopu není žádný obrazec aspektů.';

  @override
  String patternName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'grandTrine': 'Velký trigon',
      'tSquare': 'T-kvadrát',
      'grandCross': 'Velký kříž',
      'yod': 'Jod',
      'kite': 'Drak',
      'cradle': 'Kolébka',
      'mysticRectangle': 'Mystický obdélník',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String patternWithQuality(Object pattern, Object quality) {
    return '$pattern ($quality)';
  }

  @override
  String elementName(String element) {
    String _temp0 = intl.Intl.selectLogic(element, {
      'fire': 'oheň',
      'earth': 'země',
      'air': 'vzduch',
      'water': 'voda',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String modalityName(String m) {
    String _temp0 = intl.Intl.selectLogic(m, {
      'cardinal': 'kardinální',
      'fixed': 'pevný',
      'mutable': 'proměnlivý',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String modalityExcess(String m) {
    String _temp0 = intl.Intl.selectLogic(m, {
      'cardinal': 'kardinálních',
      'fixed': 'pevných',
      'mutable': 'proměnlivých',
      'other': '?',
    });
    return 'Přemíra $_temp0 znamení';
  }

  @override
  String modalityLack(String m) {
    String _temp0 = intl.Intl.selectLogic(m, {
      'cardinal': 'kardinálních',
      'fixed': 'pevných',
      'mutable': 'proměnlivých',
      'other': '?',
    });
    return 'Nedostatek $_temp0 znamení';
  }

  @override
  String hemisphereEmphasis(String h) {
    String _temp0 = intl.Intl.selectLogic(h, {
      'above': 'Důraz nad obzorem',
      'below': 'Důraz pod obzorem',
      'east': 'Důraz na východní polokouli',
      'west': 'Důraz na západní polokouli',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String unaspectedPlanet(Object planet) {
    return '$planet bez aspektu';
  }

  @override
  String patternApexTitle(Object planet, String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'tSquare': 'T-kvadrátu',
      'yod': 'jodu',
      'other': '?',
    });
    return '$planet na vrcholu $_temp0';
  }

  @override
  String patternApex(Object planets) {
    return 'vrchol: $planets';
  }

  @override
  String get textMissing => 'Text pro toto postavení zatím chybí.';

  @override
  String get timeModeTransits => 'Tranzity';

  @override
  String get timeModeProgressions => 'Progrese';

  @override
  String get timeModeSolar => 'Solár';

  @override
  String progressionsAge(Object age, Object date) {
    return 'Věk $age let · progresní den $date';
  }

  @override
  String get progressedMoon => 'Progresní Měsíc';

  @override
  String get progressedSun => 'Progresní Slunce';

  @override
  String get progressedPhase => 'Progresní fáze Měsíce';

  @override
  String progressedAngles(Object arc) {
    return 'Progresní osy (sluneční oblouk $arc)';
  }

  @override
  String get progressedAspects => 'Progresní aspekty k natálu (orb 1°)';

  @override
  String get progressedAspectsNone =>
      'Žádná progresní planeta není do 1° od aspektu k natální poloze.';

  @override
  String progressedAspectTitle(Object planet, Object aspect, Object target) {
    return 'Progresní $planet $aspect natální $target';
  }

  @override
  String progressedApplying(Object orb) {
    return '$orb · sbíhá se';
  }

  @override
  String progressedSeparating(Object orb) {
    return '$orb · rozbíhá se';
  }

  @override
  String get progressedNoTime =>
      'Bez času narození je progresní Měsíc přesný jen asi na ±6° a osy ani domy se nepočítají.';

  @override
  String get lifeTimeline => 'Časová osa života';

  @override
  String milestoneMoonSign(Object sign) {
    return 'Progresní Měsíc vstupuje do znamení $sign';
  }

  @override
  String milestoneMoonHouse(int house) {
    return 'Progresní Měsíc vstupuje do $house. domu';
  }

  @override
  String milestoneSunSign(Object sign) {
    return 'Progresní Slunce vstupuje do znamení $sign';
  }

  @override
  String milestoneLunarPhase(Object phase) {
    return 'Progresní fáze: $phase';
  }

  @override
  String milestoneSolarReturn(int year) {
    return 'Solár $year';
  }

  @override
  String milestoneAge(Object age) {
    return '$age let';
  }

  @override
  String get timelineMoonHouses => 'Domy progresního Měsíce';

  @override
  String get timelineSolarReturns => 'Soláry';

  @override
  String solarReturnTitle(int year) {
    return 'Solár $year';
  }

  @override
  String solarReturnMoment(Object lon, Object date) {
    return 'Slunce zpět na $lon: $date';
  }

  @override
  String get solarPlaceResidence => 'Bydliště';

  @override
  String get solarPlaceBirth => 'Místo narození';

  @override
  String solarPlace(Object place) {
    return 'Místo: $place';
  }

  @override
  String get solarAsc => 'Ascendent soláru';

  @override
  String get solarSunHouse => 'Slunce soláru';

  @override
  String get solarOnAngles => 'Planety na osách soláru (orb 5°)';

  @override
  String get solarNoAngles => 'Žádná planeta neleží do 5° od osy soláru.';

  @override
  String get solarPlanets => 'Planety soláru';

  @override
  String get solarNoTime =>
      'Bez času narození je natální Slunce známé jen asi na ±0,5°, okamžik soláru proto jen asi na ±12 hodin.';

  @override
  String returnAngleName(String angle) {
    String _temp0 = intl.Intl.selectLogic(angle, {
      'asc': 'ascendentu',
      'ic': 'IC',
      'dsc': 'descendentu',
      'mc': 'MC',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String planetOnAngle(Object planet, Object angle) {
    return '$planet na $angle';
  }

  @override
  String get shadowTitle => 'Stinná stránka';

  @override
  String hiddenPassages(int count, Object topics) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pasáží',
      few: '$count pasáže',
      one: '1 pasáž',
    );
    return 'Skryto: $_temp0 ($topics)';
  }

  @override
  String get helpLink =>
      'Potřebuješ si promluvit? Linka první psychické pomoci 116 123, nonstop, zdarma a anonymně';

  @override
  String get traditionNote =>
      'Tradiční výklad postavení, ne tvrzení o konkrétní osobě.';

  @override
  String get shareFull => 'Sdílet celý výklad (PDF)';

  @override
  String get oneSentence => 'Jednou větou';

  @override
  String overviewLine(Object sun, Object moon, Object asc) {
    return 'Slunce $sun, Měsíc $moon$asc';
  }

  @override
  String get transitsToday => 'Dnes';

  @override
  String get transitsTimeline => 'Den po hodinách';

  @override
  String get transitsCalendar => 'Kalendář';

  @override
  String get transitsOngoing => 'Probíhající';

  @override
  String get acute => 'akutní';

  @override
  String get now => 'teď';

  @override
  String exactAt(Object time) {
    return 'přesně $time';
  }

  @override
  String get phaseApproaching => 'blíží se';

  @override
  String get phaseExact => 'přesný';

  @override
  String get phaseSeparating => 'odeznívá';

  @override
  String pass(int n) {
    return '$n. průchod';
  }

  @override
  String passOf(int n, int total) {
    return '$n. ze $total';
  }

  @override
  String get station => 'zastávka';

  @override
  String get strength => 'síla';

  @override
  String get concurrence => 'Na týž bod míří víc tranzitů současně.';

  @override
  String get layerBackground => 'Pozadí (měsíce a roky)';

  @override
  String get layerWeeks => 'Týdny';

  @override
  String get layerDays => 'Dny';

  @override
  String get layerHours => 'Hodiny';

  @override
  String get fieldResidence => 'Místo pobytu';

  @override
  String get residenceSameAsBirth => 'Stejné jako místo narození';

  @override
  String get residenceHint =>
      'Kde teď žiješ. Podle něj se počítají planetární hodiny; poloha telefonu se nepoužívá.';

  @override
  String get settingsVocTraditional =>
      'Měsíc bez aspektu: jen tradiční planety (Slunce–Saturn)';

  @override
  String get moonAndHours => 'Měsíc a planetární hodiny';

  @override
  String moonInSign(String sign) {
    String _temp0 = intl.Intl.selectLogic(sign, {
      'aries': 'Měsíc v Beranu',
      'taurus': 'Měsíc v Býku',
      'gemini': 'Měsíc v Blížencích',
      'cancer': 'Měsíc v Raku',
      'leo': 'Měsíc ve Lvu',
      'virgo': 'Měsíc v Panně',
      'libra': 'Měsíc ve Vahách',
      'scorpio': 'Měsíc ve Štíru',
      'sagittarius': 'Měsíc ve Střelci',
      'capricorn': 'Měsíc v Kozorohu',
      'aquarius': 'Měsíc ve Vodnáři',
      'pisces': 'Měsíc v Rybách',
      'other': 'Měsíc',
    });
    return '$_temp0';
  }

  @override
  String moonPhaseName(String phase) {
    String _temp0 = intl.Intl.selectLogic(phase, {
      'new': 'Nov',
      'crescent': 'Dorůstající srpek',
      'first_quarter': 'První čtvrť',
      'gibbous': 'Dorůstající Měsíc',
      'full': 'Úplněk',
      'disseminating': 'Couvající Měsíc',
      'last_quarter': 'Poslední čtvrť',
      'balsamic': 'Ubývající srpek',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String natalMoonPhaseTitle(Object phase) {
    return 'Narození ve fázi: $phase';
  }

  @override
  String lunationName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'newMoon': 'Nov',
      'firstQuarter': 'První čtvrť',
      'fullMoon': 'Úplněk',
      'lastQuarter': 'Poslední čtvrť',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String lunationInHouse(int house, Object lunation) {
    return '$lunation v $house. domě';
  }

  @override
  String eclipseName(String kind) {
    String _temp0 = intl.Intl.selectLogic(kind, {
      'solar': 'Zatmění Slunce',
      'lunar': 'Zatmění Měsíce',
      'other': 'Zatmění',
    });
    return '$_temp0';
  }

  @override
  String eclipseDegree(String degree) {
    String _temp0 = intl.Intl.selectLogic(degree, {
      'penumbral': 'polostínové',
      'partial': 'částečné',
      'annular': 'prstencové',
      'hybrid': 'hybridní',
      'total': 'úplné',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get voidOfCourse => 'Měsíc bez aspektu';

  @override
  String voidRange(Object from, Object to) {
    return 'Měsíc bez aspektu $from – $to';
  }

  @override
  String voidAfter(Object aspect) {
    return 'po aspektu $aspect';
  }

  @override
  String get voidEnds => 'Konec Měsíce bez aspektu';

  @override
  String planetGenitive(String body) {
    String _temp0 = intl.Intl.selectLogic(body, {
      'sun': 'Slunce',
      'moon': 'Měsíce',
      'mercury': 'Merkura',
      'venus': 'Venuše',
      'mars': 'Marsu',
      'jupiter': 'Jupitera',
      'saturn': 'Saturnu',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String planetaryDay(Object planet) {
    return 'Den $planet';
  }

  @override
  String planetaryHour(Object planet) {
    return 'Hodina $planet';
  }

  @override
  String planetaryHourNumber(int n, Object part) {
    return '$n. hodina $part';
  }

  @override
  String get partDay => 'dne';

  @override
  String get partNight => 'noci';

  @override
  String get planetaryHours => 'Planetární hodiny';

  @override
  String get sunrise => 'Východ Slunce';

  @override
  String get sunset => 'Západ Slunce';

  @override
  String get noPlanetaryHours =>
      'Slunce tu tento den nevychází nebo nezapadá, planetární hodiny nejsou.';

  @override
  String moonIngressSign(Object sign) {
    return 'Měsíc vstupuje do znamení $sign';
  }

  @override
  String residenceLabel(Object place) {
    return 'Místo pobytu: $place';
  }

  @override
  String get noTransits => 'Žádné tranzity v orbu.';

  @override
  String get computing => 'Počítám…';

  @override
  String ingress(Object planet, int house) {
    return '$planet vstupuje do $house. domu';
  }

  @override
  String todaySentence(Object what) {
    return 'Dnes nejvíc působí $what.';
  }

  @override
  String get pickDate => 'Zvolit den';

  @override
  String get askTrait => 'Co to vysvětluje?';

  @override
  String get askTraitHint => 'Napiš rys, např. chaos, žárlivost, vytrvalost';

  @override
  String get askEvent => 'Co se dělo ten den?';

  @override
  String get askEventHint => 'Popis události';

  @override
  String get supports => 'Co to podporuje';

  @override
  String get speaksAgainst => 'Co mluví proti';

  @override
  String get didYouMean => 'Neznám to slovo. Možná hledáš:';

  @override
  String get noTraitMatch => 'V horoskopu k tomu není žádné postavení.';

  @override
  String get pickProfile => 'Vyber profil';

  @override
  String get electionTitle => 'Najdi termín';

  @override
  String get electionIntent => 'Záměr';

  @override
  String get electionAboutIntent => 'O záměru';

  @override
  String get electionProfile => 'Profil (místo pobytu)';

  @override
  String get electionPersonal => 'Zahrnout můj horoskop';

  @override
  String get electionPersonalHint =>
      'Přidá napětí tranzitů dne a aspekty Měsíce k tvému Slunci, Měsíci a ascendentu.';

  @override
  String get electionStart => 'Od';

  @override
  String electionDays(int days) {
    return 'Období: $days dní';
  }

  @override
  String electionHours(int from, int to) {
    return 'Hodiny dne: $from–$to';
  }

  @override
  String get electionWeekdays => 'Dny v týdnu';

  @override
  String weekdayShort(String day) {
    String _temp0 = intl.Intl.selectLogic(day, {
      '1': 'Po',
      '2': 'Út',
      '3': 'St',
      '4': 'Čt',
      '5': 'Pá',
      '6': 'So',
      '7': 'Ne',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String get electionSearch => 'Hledat';

  @override
  String electionPlace(Object place) {
    return 'Místo: $place';
  }

  @override
  String get electionDisclaimer =>
      'Okna jsou podle tradičních pravidel nejvhodnější, nejsou zárukou výsledku. Okno s Měsícem bez aspektu se nikdy nenabízí.';

  @override
  String get electionFound => 'Podle tradičních pravidel nejvhodnější okna';

  @override
  String get electionNonePassed =>
      'V tomto období neprošlo žádné okno. Nejméně špatné je toto, s důvody proti:';

  @override
  String get electionHealthNote =>
      'U zdravotních záměrů appka termín nehledá. Tradiční pravidla popisuje slovníček.';

  @override
  String electionScore(int score) {
    return 'skóre $score';
  }

  @override
  String get electionFor => 'Pro';

  @override
  String get electionAgainst => 'Proti';

  @override
  String get electionOpenChart => 'Horoskop okamžiku';

  @override
  String get electionCalendar => 'Do kalendáře';

  @override
  String get electionCalendarAll => 'Všechna okna do kalendáře';

  @override
  String electionEventTitle(Object intent) {
    return 'Termín: $intent';
  }

  @override
  String electionMomentName(Object when) {
    return 'Okamžik $when';
  }

  @override
  String get electionNeedsProfile =>
      'Pro místo pobytu potřebuješ aspoň jeden profil.';

  @override
  String electionRule(String rule) {
    String _temp0 = intl.Intl.selectLogic(rule, {
      'moon_void': 'Měsíc bez aspektu',
      'moon_waxing': 'Dorůstající Měsíc',
      'moon_next_venus': 'Měsíc míří k Venuši',
      'moon_next_jupiter': 'Měsíc míří k Jupiteru',
      'venus_angle': 'Venuše u osy',
      'jupiter_angle': 'Jupiter u osy',
      'asc_ruler_dignified': 'Vládce ascendentu silný a přímý',
      'hour_of_intent': 'Hodina planety záměru',
      'intent_planet_dignified': 'Planeta záměru silná',
      'benefic_in_intent_house': 'Dobroděj v domě záměru',
      'personal_moon_harmonious': 'Měsíc ladí s tvým horoskopem',
      'personal_calm_day': 'Klidný den v tvých tranzitech',
      'moon_next_mars_hard': 'Měsíc míří do napětí s Marsem',
      'moon_next_saturn_hard': 'Měsíc míří do napětí se Saturnem',
      'mars_angle': 'Mars u osy',
      'saturn_angle': 'Saturn u osy',
      'intent_planet_retrograde': 'Planeta záměru retrográdní',
      'intent_planet_fall': 'Planeta záměru v pádu',
      'intent_planet_detriment': 'Planeta záměru ve zničení',
      'asc_ruler_bad_house': 'Vládce ascendentu v 6., 8. nebo 12. domě',
      'asc_ruler_retrograde': 'Vládce ascendentu retrográdní',
      'eclipse': 'Blízko zatmění',
      'via_combusta': 'Měsíc ve spálené cestě',
      'malefic_in_intent_house': 'Zhoubce v domě záměru',
      'personal_moon_tense': 'Měsíc v napětí s tvým horoskopem',
      'personal_tension_high': 'Napjatý den v tvých tranzitech',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String electionIntentName(String intent) {
    String _temp0 = intl.Intl.selectLogic(intent, {
      'relationship': 'Svatba, vztah',
      'contract': 'Smlouva, podpis, jednání',
      'launch': 'Zahájení podnikání, projektu',
      'money': 'Peníze, nákup',
      'move': 'Stěhování, nemovitost',
      'travel': 'Cesta',
      'study': 'Zkouška, studium',
      'application': 'Žádost, pohovor',
      'surgery': 'Operace, zákrok',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String electionVerdict(String verdict) {
    String _temp0 = intl.Intl.selectLogic(verdict, {
      'strong': 'Velmi vhodné',
      'good': 'Vhodné',
      'weak': 'Slabé',
      'none': 'Nejméně špatné',
      'health': 'Termín se nehledá',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String dayPercentile(int p) {
    return 'Napětí dne: víc než $p % dnů života';
  }

  @override
  String get tense => 'Napěťové';

  @override
  String get harmonious => 'Harmonické';

  @override
  String get connectionsNotProof =>
      'Appka ukazuje souvislosti podle tradice, ne důkazy.';

  @override
  String get settingsFilter => 'Co nechci vidět';

  @override
  String get settingsShadow => 'Stinné stránky povahy';

  @override
  String get gentleMode => 'Šetrný režim';

  @override
  String get gentleModeDesc => 'Skryje všechna těžká témata jedním ťuknutím.';

  @override
  String get settingsHouses => 'Výchozí systém domů';

  @override
  String get settingsOrbs => 'Těsné orby (3°)';

  @override
  String get settingsNode => 'Pravý uzel místo středního';

  @override
  String get settingsAbout => 'O appce a zdrojích';

  @override
  String get onboardingTitle => 'Než začneš';

  @override
  String get onboardingBody =>
      'Výklad obsahuje i stinné stránky a těžká témata, o kterých tradiční astrologie mluví: nemoc, ztrátu, smrt, krize. Všechno je to tradiční výklad, ne předpověď.';

  @override
  String get onboardingGentle =>
      'Nebudu ti zobrazovat to, co by ti mohlo ublížit. Ukaž to svému terapeutovi, nedívej se na to o samotě.';

  @override
  String get onboardingShowAll => 'Zobrazovat všechno';

  @override
  String get onboardingUseGentle => 'Zapnout šetrný režim';

  @override
  String get onboardingHint =>
      'Šetrný režim doporučujeme, pokud procházíš těžkým obdobím. Nastavení jde kdykoli změnit.';

  @override
  String get peopleEmpty =>
      'Katalog osobností zatím nemá žádný záznam s ověřeným zdrojem. Záznamy přibudou, až bude každý čas narození doložený.';

  @override
  String get reliability => 'Spolehlivost času';

  @override
  String get source => 'Zdroj';

  @override
  String reliabilityBadge(String grade) {
    String _temp0 = intl.Intl.selectLogic(grade, {
      'AA': 'potvrzeno (AA)',
      'A': 'potvrzeno (A)',
      'B': 'čas ze životopisu (B)',
      'C': 'čas nejistý (C)',
      'other': 'bez času (X)',
    });
    return '$_temp0';
  }

  @override
  String reliabilityWarning(String grade) {
    String _temp0 = intl.Intl.selectLogic(grade, {
      'B':
          'Čas narození pochází ze životopisu, ne z matriky. Ascendent a domy ber s rezervou.',
      'C':
          'Čas narození je nejistý a bez doloženého původu. Ascendent a domy mohou být úplně jinde.',
      'X':
          'Čas narození není doložený. Horoskop je bez domů a ascendentu; Měsíc se může lišit až o několik stupňů.',
      'other': '',
    });
    return '$_temp0';
  }

  @override
  String get peopleAll => 'Všichni';

  @override
  String peopleCategory(String cat) {
    String _temp0 = intl.Intl.selectLogic(cat, {
      'history': 'Historie',
      'politics': 'Politika',
      'military': 'Vojevůdci',
      'science': 'Věda',
      'art': 'Výtvarné umění',
      'music': 'Hudba',
      'film': 'Film',
      'celebrity': 'Celebrity',
      'football': 'Fotbal',
      'hockey': 'Hokej',
      'sport': 'Sport',
      'business': 'Byznys',
      'religion': 'Náboženství',
      'literature': 'Literatura',
      'other': 'Ostatní',
    });
    return '$_temp0';
  }

  @override
  String get peopleSearch => 'Hledej osobnost';

  @override
  String get peopleSourceNote =>
      'Data narození a místa: Wikidata (CC0). Čas jen tam, kde je doložený zdroj.';

  @override
  String get glossarySearch => 'Hledej pojem';

  @override
  String get aboutText =>
      'Výpočet běží v telefonu, data narození ho neopouštějí. Polohy: VSOP87 a Meeus (balíček astronomia, MIT), Pluto z efemeridy JPL DE440. Místa: GeoNames (CC BY 4.0). Osobnosti: Wikidata (CC0). Symboly: Noto Sans Symbols (SIL OFL). Texty výkladu jsou vlastní a popisují tradici, ne prokázané souvislosti.';

  @override
  String bodyName(String body) {
    String _temp0 = intl.Intl.selectLogic(body, {
      'sun': 'Slunce',
      'moon': 'Měsíc',
      'mercury': 'Merkur',
      'venus': 'Venuše',
      'mars': 'Mars',
      'jupiter': 'Jupiter',
      'saturn': 'Saturn',
      'uranus': 'Uran',
      'neptune': 'Neptun',
      'pluto': 'Pluto',
      'meanNode': 'Uzel',
      'trueNode': 'Uzel',
      'asc': 'Ascendent',
      'mc': 'MC',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String signName(String sign) {
    String _temp0 = intl.Intl.selectLogic(sign, {
      'aries': 'Beran',
      'taurus': 'Býk',
      'gemini': 'Blíženci',
      'cancer': 'Rak',
      'leo': 'Lev',
      'virgo': 'Panna',
      'libra': 'Váhy',
      'scorpio': 'Štír',
      'sagittarius': 'Střelec',
      'capricorn': 'Kozoroh',
      'aquarius': 'Vodnář',
      'pisces': 'Ryby',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String aspectName(String aspect) {
    String _temp0 = intl.Intl.selectLogic(aspect, {
      'conjunction': 'konjunkce',
      'sextile': 'sextil',
      'square': 'kvadrát',
      'trine': 'trigon',
      'opposition': 'opozice',
      'quincunx': 'kvinkunx',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String houseSystemName(String system) {
    String _temp0 = intl.Intl.selectLogic(system, {
      'placidus': 'Placidus',
      'koch': 'Koch',
      'regiomontanus': 'Regiomontanus',
      'campanus': 'Campanus',
      'porphyry': 'Porphyry',
      'equal': 'Equal',
      'wholeSign': 'Celá znamení',
      'meridian': 'Meridian',
      'morinus': 'Morinus',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String dignityName(String d) {
    String _temp0 = intl.Intl.selectLogic(d, {
      'domicile': 'vládne',
      'exaltation': 'v povýšení',
      'detriment': 've zničení',
      'fall': 'v pádu',
      'peregrine': '—',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String hardTopicName(String t) {
    String _temp0 = intl.Intl.selectLogic(t, {
      'death': 'smrt',
      'illness': 'nemoc',
      'mental_crisis': 'duševní krize',
      'addiction': 'závislost',
      'violence': 'násilí',
      'loss': 'ztráta',
      'ruin': 'úpadek',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String themeName(String t) {
    String _temp0 = intl.Intl.selectLogic(t, {
      'character': 'Povaha',
      'relationships': 'Vztahy',
      'family': 'Rodina',
      'work': 'Práce',
      'money': 'Peníze',
      'health': 'Zdraví',
      'growth': 'Růst',
      'other': 'Ostatní',
    });
    return '$_temp0';
  }

  @override
  String houseN(int n) {
    return '$n. dům';
  }

  @override
  String get retrogradeShort => 'R';

  @override
  String transitTitle(Object planet, Object aspect, Object target) {
    return '$planet $aspect natální $target';
  }

  @override
  String get stars => 'Stálice';

  @override
  String get sectionStars => 'Stálice';

  @override
  String get starsOnWheel => 'Stálice na kole';

  @override
  String get starsFilterNote =>
      'Se zapnutým filtrem zbude u většiny stálic jen základní text, protože tradice o nich mluví hlavně ve stinné vrstvě a v těžkých tématech.';

  @override
  String get starsNone =>
      'Žádná planeta ani osa neleží do 1° od některé z 32 stálic.';

  @override
  String get starsAll => 'Všech 32 stálic';

  @override
  String starContact(Object point, Object orb) {
    return 'konjunkce: $point · orb $orb';
  }

  @override
  String starName(String star) {
    String _temp0 = intl.Intl.selectLogic(star, {
      'algol': 'Algol',
      'alcyone': 'Alkyone',
      'aldebaran': 'Aldebaran',
      'rigel': 'Rigel',
      'bellatrix': 'Bellatrix',
      'capella': 'Capella',
      'betelgeuse': 'Betelgeuze',
      'sirius': 'Sírius',
      'castor': 'Castor',
      'pollux': 'Pollux',
      'procyon': 'Prokyon',
      'praesepe': 'Praesepe',
      'alphard': 'Alphard',
      'regulus': 'Regulus',
      'denebola': 'Denebola',
      'vindemiatrix': 'Vindemiatrix',
      'algorab': 'Algorab',
      'spica': 'Spica',
      'arcturus': 'Arcturus',
      'zubenelgenubi': 'Zubenelgenubi',
      'zubeneschamali': 'Zubeneschamali',
      'unukalhai': 'Unukalhai',
      'acrab': 'Akrab',
      'antares': 'Antares',
      'rasalhague': 'Ras Alhague',
      'vega': 'Vega',
      'altair': 'Altair',
      'deneb_algedi': 'Deneb Algedi',
      'fomalhaut': 'Fomalhaut',
      'achernar': 'Achernar',
      'markab': 'Markab',
      'scheat': 'Scheat',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String get journalTitle => 'Deník předpovědí';

  @override
  String get journalRateToday => 'Ohodnotit dnešek';

  @override
  String get journalRateYesterday => 'Ohodnotit včerejšek';

  @override
  String get journalChangeRating => 'Změnit hodnocení';

  @override
  String get journalAddCorrection => 'Přidat opravu';

  @override
  String get journalClosedNote =>
      'Den je uzavřený. Změna se zapíše jako oprava s odkazem na původní záznam; vyhodnocuje se původní hodnocení.';

  @override
  String journalOpenUntil(Object day) {
    return 'Hodnocení jde měnit do konce dne $day.';
  }

  @override
  String journalRatingLabel(Object day) {
    return 'Jaký byl den $day?';
  }

  @override
  String journalRatingValue(String value) {
    String _temp0 = intl.Intl.selectLogic(value, {
      'm2': 'velmi špatný',
      'm1': 'spíš špatný',
      'zero': 'běžný',
      'p1': 'spíš dobrý',
      'p2': 'velmi dobrý',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String get journalTags => 'Štítky';

  @override
  String get journalTagSearch => 'Přidat štítek (např. únava)';

  @override
  String get journalNote => 'Poznámka';

  @override
  String get journalSave => 'Uložit';

  @override
  String get journalHistory => 'Ohodnocené dny';

  @override
  String get journalEmpty => 'Zatím žádné hodnocení.';

  @override
  String get journalSawPrediction => 'předpověď byla vidět';

  @override
  String get journalBlindFlag => 'naslepo';

  @override
  String journalCorrectionOf(Object value) {
    return 'oprava, původně $value';
  }

  @override
  String journalTension(Object value) {
    return 'napětí $value';
  }

  @override
  String get journalExport => 'Exportovat CSV';

  @override
  String get journalBlindTitle => 'Slepý test';

  @override
  String get journalBlindOff =>
      'Na 90 dní skryje tranzity, dokud dnešek neohodnotíš. Dobrovolné, výchozí vypnuto.';

  @override
  String journalBlindRunning(Object day) {
    return 'Běží do $day. Tranzity se odemknou po ohodnocení dne.';
  }

  @override
  String get journalBlindLocked =>
      'Slepý test: tranzity se odemknou, až ohodnotíš dnešek.';

  @override
  String get journalBlindStopConfirm =>
      'Ukončit slepý test předčasně? Další hodnocení ponesou příznak, že předpověď byla vidět.';

  @override
  String get journalEvaluation => 'Vyhodnocení';

  @override
  String get journalGroupBlind => 'Hodnocení naslepo';

  @override
  String get journalGroupSeen => 'Hodnocení s viditelnou předpovědí';

  @override
  String journalTooFew(Object n, Object min) {
    return 'Zatím málo dat: $n z $min ohodnocených dní.';
  }

  @override
  String get journalUndefined =>
      'Hodnocení nebo napětí se nemění, souvislost nejde spočítat.';

  @override
  String get journalResultExpected =>
      'Ve dnech s vyšším napětím hodnotíš den hůř.';

  @override
  String get journalResultOpposite =>
      'Ve dnech s vyšším napětím hodnotíš den lépe.';

  @override
  String get journalResultNone =>
      'Souvislost mezi napětím a hodnocením se neukázala.';

  @override
  String journalResultNumbers(
    Object rho,
    Object size,
    Object p,
    Object perms,
    Object n,
    Object weeks,
  ) {
    return 'Pořadová korelace ρ = $rho, $size efekt. Stejnou nebo silnější shodu dalo náhodné přeházení celých týdnů v $p pokusů z $perms ($n dní, $weeks týdnů).';
  }

  @override
  String journalEffect(String size) {
    String _temp0 = intl.Intl.selectLogic(size, {
      'negligible': 'zanedbatelný',
      'small': 'malý',
      'moderate': 'střední',
      'large': 'velký',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String get journalControl => 'Kontrola cizím horoskopem';

  @override
  String journalControlResult(
    Object persons,
    Object k,
    Object own,
    Object median,
  ) {
    return 'Tranzity k $persons cizím horoskopům z katalogu: stejně dobře nebo lépe sedí $k z nich (tvoje ρ = $own, medián cizích ρ = $median).';
  }

  @override
  String journalControlFew(Object n, Object min) {
    return 'V katalogu je zatím $n osob; kontrola potřebuje aspoň $min.';
  }

  @override
  String journalControlPartial(Object n, Object want) {
    return 'Katalog má zatím jen $n osob místo $want.';
  }

  @override
  String get journalControlBetter => 'Vlastní horoskop sedí líp než cizí.';

  @override
  String get journalControlNotBetter => 'Vlastní horoskop nesedí líp než cizí.';

  @override
  String get journalHypotheses => 'Vlastní hypotézy';

  @override
  String get journalHypothesisAdd => 'Zapsat hypotézu';

  @override
  String journalHypothesisRule(Object transit, Object tag) {
    return '$transit → $tag';
  }

  @override
  String journalHypothesisSince(Object day) {
    return 'Zapsáno $day; počítají se jen dny potom.';
  }

  @override
  String journalHypothesisResult(
    Object a,
    Object n,
    Object pa,
    Object b,
    Object m,
    Object pb,
  ) {
    return 'S tranzitem: štítek $a z $n dní ($pa). Bez tranzitu: $b z $m dní ($pb).';
  }

  @override
  String journalHypothesisFew(Object min) {
    return 'Zatím málo dní: potřeba aspoň $min s tranzitem i bez něj.';
  }

  @override
  String journalHypothesisMore(Object p) {
    return 'Štítek se při tranzitu objevuje častěji, než by dala náhoda (p = $p).';
  }

  @override
  String journalHypothesisNotMore(Object p) {
    return 'Štítek se při tranzitu neobjevuje častěji, než by dala náhoda (p = $p).';
  }

  @override
  String get journalHypothesisTransiting => 'Tranzitující planeta';

  @override
  String get journalHypothesisAspect => 'Aspekt';

  @override
  String get journalHypothesisTarget => 'Natální bod';

  @override
  String get journalHypothesisTag => 'Štítek';

  @override
  String get journalHypothesisDelete => 'Smazat hypotézu';

  @override
  String get journalHypothesisNoTag => 'Vyber štítek ze slovníku.';

  @override
  String get journalTextMissing => 'Text zatím chybí.';

  @override
  String get journalMethod => 'Jak to funguje';

  @override
  String get journalReminder => 'Večerní připomínka deníku';

  @override
  String journalReminderDesc(Object time) {
    return 'Místní oznámení v telefonu, bez sítě. Čas: $time.';
  }

  @override
  String get journalReminderTitle => 'Deník předpovědí';

  @override
  String get journalReminderBody => 'Jaký byl dnešek? Ohodnoť den.';

  @override
  String get journalReminderDenied =>
      'Oznámení nejsou povolená. Povol je v nastavení telefonu.';

  @override
  String get journalErrorNewer =>
      'Deník uložila novější verze appky. Aktualizuj appku; data zůstávají beze změny.';

  @override
  String get synastryTitle => 'Partnerský horoskop';

  @override
  String get synastryIntro =>
      'Srovnání dvou uložených profilů: aspekty mezi planetami, planety jedné osoby v domech druhé.';

  @override
  String get synastryFirst => 'První osoba';

  @override
  String get synastrySecond => 'Druhá osoba';

  @override
  String get synastryRelationship => 'Typ vztahu';

  @override
  String relationshipName(String type) {
    String _temp0 = intl.Intl.selectLogic(type, {
      'partner': 'Partneři',
      'parentChild': 'Rodič a dítě',
      'siblings': 'Sourozenci',
      'friends': 'Přátelé',
      'colleagues': 'Kolegové',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String get synastryCompare => 'Porovnat';

  @override
  String get synastryNeedTwo =>
      'Pro srovnání potřebuješ aspoň dva uložené profily.';

  @override
  String get synastrySamePerson => 'Vyber dvě různé osoby.';

  @override
  String get tabWheel => 'Kolo';

  @override
  String synastryWheelLegend(Object first, Object second) {
    return 'Vnitřní kruh: $first · vnější kruh: $second';
  }

  @override
  String get synastryAspects => 'Aspekty mezi vámi';

  @override
  String get synastryNoAspects => 'Mezi horoskopy není žádný aspekt v orbech.';

  @override
  String synastryHousesOf(Object owner, Object host) {
    return 'Planety: $owner · domy: $host';
  }

  @override
  String synastryNoHouses(Object name) {
    return '$name: bez času narození nejsou domy ani osy.';
  }

  @override
  String synastryPointOf(Object point, Object name) {
    return '$point ($name)';
  }

  @override
  String get synastryPartnerTitle => 'Partnerský dovětek';

  @override
  String get sectionSynastryAspects => 'Aspekty mezi planetami';

  @override
  String get sectionSynastryPoints => 'Planety na osách druhého';

  @override
  String get sectionSynastryHouses => 'Planety v domech druhého';

  @override
  String get twinsTitle => 'Horoskopy jsou skoro stejné';

  @override
  String twinsBody(Object diff, Object minutes) {
    return 'Všechny planety leží do 1° od sebe (nejvíc $diff), takže místo deseti konjunkcí ukazujeme jen to, co se liší. Narození dělí $minutes min.';
  }

  @override
  String twinsAxes(Object asc, Object mc) {
    return 'Ascendent se liší o $asc, MC o $mc.';
  }

  @override
  String twinsCusps(Object min, Object max) {
    return 'Hroty domů se liší o $min až $max.';
  }

  @override
  String get twinsNoTime =>
      'Bez času narození nejde říct, jak se liší osy a domy.';

  @override
  String twinsHouseChange(Object planet, Object from, Object to) {
    return '$planet: $from. dům → $to. dům';
  }

  @override
  String get twinsNoHouseChange =>
      'Všechny planety zůstávají ve stejných domech.';

  @override
  String get twinsGlossary => 'Proč jsou dvojčata různá';

  @override
  String synastryPairTitle(Object first, Object second) {
    return '$first a $second';
  }

  @override
  String get horaryMode => 'Horární';

  @override
  String get horaryIntro =>
      'Horoskop se staví na okamžik, kdy otázku potvrdíš. Ptej se na jednu konkrétní věc a na každou jen jednou.';

  @override
  String get horaryAbout => 'Jak se horární otázka čte';

  @override
  String get horaryAboutHealth =>
      'Zdraví, smrt a těhotenství v horární tradici';

  @override
  String get horaryQuestion => 'Tvoje otázka';

  @override
  String get horaryQuestionHint =>
      'Jen pro tebe. Appka text nečte, ukládá ho šifrovaně v telefonu.';

  @override
  String get horaryTopic => 'Téma';

  @override
  String get horaryPerson => 'O kom je otázka';

  @override
  String horaryHouseUsed(int house) {
    return 'Dům věci: $house.';
  }

  @override
  String horaryHouseShort(int house) {
    return '$house. dům';
  }

  @override
  String get horaryAsk => 'Potvrdit otázku';

  @override
  String get horaryMomentNote =>
      'Okamžikem otázky je chvíle potvrzení, místem tvé místo pobytu z profilu.';

  @override
  String get horaryNoVerdict =>
      'U otázek na zdraví, smrt a těhotenství appka verdikt nedává. Tradiční pravidla popisuje slovníček.';

  @override
  String get horaryNoVerdictShort => 'bez verdiktu';

  @override
  String get horaryRepeatTitle => 'Stejné téma znovu';

  @override
  String horaryRepeatBody(Object when) {
    return 'Na stejné téma padla otázka $when. Tradice druhý pokus do 24 hodin nebere; platí první horoskop.';
  }

  @override
  String get horaryShowFirst => 'Ukázat první horoskop';

  @override
  String horaryMoment(Object when, Object place) {
    return 'Okamžik otázky: $when, $place';
  }

  @override
  String horaryVerdictLine(Object verdict) {
    return 'Podle tradičních pravidel vychází: $verdict';
  }

  @override
  String horaryVerdictName(String verdict) {
    String _temp0 = intl.Intl.selectLogic(verdict, {
      'yes': 'ano',
      'yes_difficult': 'ano, ale s potížemi',
      'no': 'ne',
      'past': 'už je to pryč',
      'nothing': 'nic z toho nebude',
      'unclear': 'nelze říct',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String get horaryDisclaimer =>
      'Výsledek čte horoskop podle pravidel 17. století. Není to předpověď ani rada.';

  @override
  String horaryTestimony(String rule) {
    String _temp0 = intl.Intl.selectLogic(rule, {
      'perfection_conjunction': 'Ukazatelé se spojí',
      'perfection_sextile': 'Dokonání sextilem',
      'perfection_trine': 'Dokonání trigonem',
      'perfection_square': 'Dokonání kvadrátem',
      'perfection_opposition': 'Dokonání opozicí',
      'moon_perfection': 'Měsíc dojde k ukazateli věci',
      'translation': 'Přenos světla',
      'collection': 'Sběr světla',
      'reception': 'Přijetí',
      'mutual_reception': 'Vzájemné přijetí',
      'querent_strong': 'Tvůj ukazatel je silný',
      'quesited_strong': 'Ukazatel věci je silný',
      'quesited_in_first': 'Ukazatel věci v domě tazatele',
      'querent_in_quesited_house': 'Tvůj ukazatel v domě věci',
      'natural_perfection': 'Přirozený ukazatel se připojí',
      'separating': 'Ukazatelé se rozcházejí',
      'no_aspect': 'Ukazatelé se nesetkají',
      'prohibition': 'Zábrana',
      'frustration': 'Zmaření',
      'refranation': 'Ústup',
      'combustion': 'Spálení ukazatele',
      'hard_without_reception': 'Napětí bez přijetí',
      'querent_weak': 'Tvůj ukazatel je slabý',
      'quesited_weak': 'Ukazatel věci je slabý',
      'querent_retrograde': 'Tvůj ukazatel couvá',
      'quesited_retrograde': 'Ukazatel věci couvá',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String get horaryConsiderations => 'Výhrady před výkladem';

  @override
  String get horaryConsiderationNote =>
      'Výhrady výklad neblokují. Tradice jimi upozorňuje, že horoskop nemusí být k otázce způsobilý.';

  @override
  String get horaryConsiderationsNone => 'Žádné výhrady.';

  @override
  String horaryConsideration(String rule) {
    String _temp0 = intl.Intl.selectLogic(rule, {
      'asc_early': 'Ascendent v prvních stupních znamení',
      'asc_late': 'Ascendent v posledních stupních znamení',
      'moon_void': 'Měsíc bez aspektu',
      'via_combusta': 'Měsíc ve spálené cestě',
      'saturn_1_7': 'Saturn v 1. nebo 7. domě',
      'hour_ruler': 'Vládce hodiny nesouhlasí s ascendentem',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String get horaryTimingTitle => 'Tradiční odhad času';

  @override
  String horaryTimingLine(Object degrees, Object unit) {
    return 'Do dokonání zbývá $degrees°, podle tradice tedy asi $unit. Je to odhad, ne termín.';
  }

  @override
  String get horaryTimingUnknown =>
      'Pro toto postavení tradice jednotku času neurčuje.';

  @override
  String horaryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dní',
      few: '$count dny',
      one: '1 den',
    );
    return '$_temp0';
  }

  @override
  String horaryWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count týdnů',
      few: '$count týdny',
      one: '1 týden',
    );
    return '$_temp0';
  }

  @override
  String horaryMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count měsíců',
      few: '$count měsíce',
      one: '1 měsíc',
    );
    return '$_temp0';
  }

  @override
  String horaryYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count let',
      few: '$count roky',
      one: '1 rok',
    );
    return '$_temp0';
  }

  @override
  String get horaryLostTitle => 'Ztracená věc';

  @override
  String horaryLostLine(Object bySign, Object sign, Object byHouse, int house) {
    return 'Podle znamení ($sign) směr $bySign, podle $house. domu směr $byHouse.';
  }

  @override
  String get horarySignificators => 'Ukazatelé';

  @override
  String horaryQuerent(int house) {
    return 'Tazatel ($house. dům)';
  }

  @override
  String get horaryCoQuerent => 'Měsíc, druhý ukazatel tazatele';

  @override
  String horaryQuesited(int house) {
    return 'Věc ($house. dům)';
  }

  @override
  String get horaryNatural => 'Přirozený ukazatel věci';

  @override
  String horaryStrength(int total, int essential, int accidental) {
    return 'síla $total (bytostná $essential, nahodilá $accidental)';
  }

  @override
  String get horaryLogTitle => 'Deník otázek';

  @override
  String get horaryLogEmpty => 'Zatím žádné otázky.';

  @override
  String get horaryFollowUp => 'Jak to dopadlo?';

  @override
  String horaryOutcomeName(String outcome) {
    String _temp0 = intl.Intl.selectLogic(outcome, {
      'yes': 'Ano',
      'no': 'Ne',
      'other': 'Jinak, nevím',
    });
    return '$_temp0';
  }

  @override
  String horaryOutcomeSet(Object outcome) {
    return 'Jak to dopadlo: $outcome';
  }

  @override
  String horaryHitRate(int rate, int n, int yes, int no) {
    return 'Zásahy: $rate % z $n uzavřených otázek s odpovědí ano nebo ne. Kdyby appka vždycky řekla ano: $yes %, vždycky ne: $no %.';
  }

  @override
  String horaryHitRateTooFew(int min, int n) {
    return 'Podíl zásahů appka ukáže od $min uzavřených otázek s odpovědí ano nebo ne. Uzavřených otázek: $n.';
  }

  @override
  String get horaryPdf => 'Export do PDF';

  @override
  String get horaryPdfTitle => 'Export otázky do PDF';

  @override
  String get horaryPdfIncludeText => 'Přidat do PDF i text otázky';

  @override
  String horaryTopicName(String topic) {
    String _temp0 = intl.Intl.selectLogic(topic, {
      'money': 'Peníze',
      'property': 'Majetek',
      'lost_object': 'Ztracená věc',
      'siblings': 'Sourozenci',
      'short_trip': 'Krátká cesta',
      'message': 'Zpráva, dopis',
      'home': 'Domov',
      'real_estate': 'Nemovitost',
      'parents': 'Rodiče',
      'children': 'Děti',
      'love': 'Láska',
      'game': 'Hra, sázka',
      'daily_work': 'Každodenní práce',
      'employees': 'Podřízení',
      'pet': 'Domácí zvíře',
      'partner': 'Partner, partnerka',
      'contract': 'Smlouva',
      'dispute': 'Spor',
      'opponent': 'Protivník',
      'debts': 'Dluhy',
      'inheritance': 'Dědictví',
      'others_money': 'Cizí peníze',
      'long_trip': 'Dálková cesta',
      'study': 'Studium',
      'law': 'Úřady a právo',
      'career': 'Kariéra, místo',
      'position': 'Postavení, funkce',
      'superior': 'Nadřízený',
      'friends': 'Přátelé',
      'wish': 'Přání',
      'hidden': 'Skryté věci',
      'secret_enemies': 'Tajní nepřátelé',
      'health': 'Zdraví, nemoc',
      'death': 'Smrt',
      'pregnancy': 'Těhotenství',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String horaryPersonName(String person) {
    String _temp0 = intl.Intl.selectLogic(person, {
      'self': 'Já',
      'sibling': 'Sourozenec',
      'child': 'Dítě',
      'partner': 'Partner, partnerka',
      'father': 'Otec',
      'mother': 'Matka',
      'friend': 'Přítel, přítelkyně',
      'other': '?',
    });
    return '$_temp0';
  }

  @override
  String horaryDirection(String dir) {
    String _temp0 = intl.Intl.selectLogic(dir, {
      'east': 'východ',
      'east_by_north': 'východ k severu',
      'east_by_south': 'východ k jihu',
      'west': 'západ',
      'west_by_south': 'západ k jihu',
      'west_by_north': 'západ k severu',
      'north': 'sever',
      'north_by_east': 'sever k východu',
      'north_by_west': 'sever k západu',
      'south': 'jih',
      'south_by_east': 'jih k východu',
      'south_by_west': 'jih k západu',
      'northeast_by_east': 'severovýchod k východu',
      'north_northeast': 'severoseverovýchod',
      'northwest_by_north': 'severozápad k severu',
      'west_northwest': 'západoseverozápad',
      'southwest_by_south': 'jihozápad k jihu',
      'south_southwest': 'jihojihozápad',
      'southeast_by_south': 'jihovýchod k jihu',
      'east_southeast': 'východojihovýchod',
      'other': '?',
    });
    return '$_temp0';
  }
}
