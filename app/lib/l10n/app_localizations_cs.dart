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
}
