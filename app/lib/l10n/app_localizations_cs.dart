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
  String get textMissing => 'Text pro toto postavení zatím chybí.';

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
  String get glossarySearch => 'Hledej pojem';

  @override
  String get aboutText =>
      'Výpočet běží v telefonu, data narození ho neopouštějí. Polohy: VSOP87 a Meeus (balíček astronomia, MIT), Pluto z efemeridy JPL DE440. Místa: GeoNames (CC BY 4.0). Symboly: Noto Sans Symbols (SIL OFL). Texty výkladu jsou vlastní a popisují tradici, ne prokázané souvislosti.';

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
}
