import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_cs.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('cs')];

  /// No description provided for @appTitle.
  ///
  /// In cs, this message translates to:
  /// **'Astro'**
  String get appTitle;

  /// No description provided for @navProfiles.
  ///
  /// In cs, this message translates to:
  /// **'Profily'**
  String get navProfiles;

  /// No description provided for @navPeople.
  ///
  /// In cs, this message translates to:
  /// **'Osobnosti'**
  String get navPeople;

  /// No description provided for @navAsk.
  ///
  /// In cs, this message translates to:
  /// **'Zeptej se'**
  String get navAsk;

  /// No description provided for @navGlossary.
  ///
  /// In cs, this message translates to:
  /// **'Slovníček'**
  String get navGlossary;

  /// No description provided for @navSettings.
  ///
  /// In cs, this message translates to:
  /// **'Nastavení'**
  String get navSettings;

  /// No description provided for @profilesEmpty.
  ///
  /// In cs, this message translates to:
  /// **'Zatím žádný profil. Přidej první horoskop.'**
  String get profilesEmpty;

  /// No description provided for @addProfile.
  ///
  /// In cs, this message translates to:
  /// **'Přidat profil'**
  String get addProfile;

  /// No description provided for @editProfile.
  ///
  /// In cs, this message translates to:
  /// **'Upravit profil'**
  String get editProfile;

  /// No description provided for @deleteProfile.
  ///
  /// In cs, this message translates to:
  /// **'Smazat profil'**
  String get deleteProfile;

  /// No description provided for @deleteProfileConfirm.
  ///
  /// In cs, this message translates to:
  /// **'Smazat profil {name}? Nejde to vrátit.'**
  String deleteProfileConfirm(Object name);

  /// No description provided for @cancel.
  ///
  /// In cs, this message translates to:
  /// **'Zrušit'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In cs, this message translates to:
  /// **'Uložit'**
  String get save;

  /// No description provided for @delete.
  ///
  /// In cs, this message translates to:
  /// **'Smazat'**
  String get delete;

  /// No description provided for @ok.
  ///
  /// In cs, this message translates to:
  /// **'Rozumím'**
  String get ok;

  /// No description provided for @fieldName.
  ///
  /// In cs, this message translates to:
  /// **'Jméno'**
  String get fieldName;

  /// No description provided for @fieldDate.
  ///
  /// In cs, this message translates to:
  /// **'Datum narození'**
  String get fieldDate;

  /// No description provided for @fieldTime.
  ///
  /// In cs, this message translates to:
  /// **'Čas narození'**
  String get fieldTime;

  /// No description provided for @timeUnknown.
  ///
  /// In cs, this message translates to:
  /// **'Čas neznám'**
  String get timeUnknown;

  /// No description provided for @fieldPlace.
  ///
  /// In cs, this message translates to:
  /// **'Místo narození'**
  String get fieldPlace;

  /// No description provided for @placeSearchHint.
  ///
  /// In cs, this message translates to:
  /// **'Hledej obec nebo město'**
  String get placeSearchHint;

  /// No description provided for @manualCoords.
  ///
  /// In cs, this message translates to:
  /// **'Zadat souřadnice ručně'**
  String get manualCoords;

  /// No description provided for @fieldLat.
  ///
  /// In cs, this message translates to:
  /// **'Zeměpisná šířka (°, sever +)'**
  String get fieldLat;

  /// No description provided for @fieldLon.
  ///
  /// In cs, this message translates to:
  /// **'Zeměpisná délka (°, východ +)'**
  String get fieldLon;

  /// No description provided for @fieldZone.
  ///
  /// In cs, this message translates to:
  /// **'Časové pásmo (IANA)'**
  String get fieldZone;

  /// No description provided for @timeBasis.
  ///
  /// In cs, this message translates to:
  /// **'Jak číst čas'**
  String get timeBasis;

  /// No description provided for @basisZone.
  ///
  /// In cs, this message translates to:
  /// **'Místní čas'**
  String get basisZone;

  /// No description provided for @basisUt.
  ///
  /// In cs, this message translates to:
  /// **'Zadávám UT'**
  String get basisUt;

  /// No description provided for @basisLmt.
  ///
  /// In cs, this message translates to:
  /// **'Místní střední čas'**
  String get basisLmt;

  /// No description provided for @calendar.
  ///
  /// In cs, this message translates to:
  /// **'Kalendář'**
  String get calendar;

  /// No description provided for @calGregorian.
  ///
  /// In cs, this message translates to:
  /// **'gregoriánský'**
  String get calGregorian;

  /// No description provided for @calJulian.
  ///
  /// In cs, this message translates to:
  /// **'juliánský'**
  String get calJulian;

  /// No description provided for @houseSystemField.
  ///
  /// In cs, this message translates to:
  /// **'Systém domů'**
  String get houseSystemField;

  /// No description provided for @houseSystemAuto.
  ///
  /// In cs, this message translates to:
  /// **'Automaticky podle šířky'**
  String get houseSystemAuto;

  /// No description provided for @dstAmbiguous.
  ///
  /// In cs, this message translates to:
  /// **'Tento čas při změně letního času nastal dvakrát nebo vůbec. Zkontroluj ho, případně zadej UT.'**
  String get dstAmbiguous;

  /// No description provided for @lmtNotice.
  ///
  /// In cs, this message translates to:
  /// **'Čas před zavedením pásmového času: počítá se místní střední čas místa narození.'**
  String get lmtNotice;

  /// No description provided for @tabOverview.
  ///
  /// In cs, this message translates to:
  /// **'Přehled'**
  String get tabOverview;

  /// No description provided for @tabTables.
  ///
  /// In cs, this message translates to:
  /// **'Tabulky'**
  String get tabTables;

  /// No description provided for @tabReading.
  ///
  /// In cs, this message translates to:
  /// **'Výklad'**
  String get tabReading;

  /// No description provided for @tabTransits.
  ///
  /// In cs, this message translates to:
  /// **'Tranzity'**
  String get tabTransits;

  /// No description provided for @positions.
  ///
  /// In cs, this message translates to:
  /// **'Pozice planet'**
  String get positions;

  /// No description provided for @houses.
  ///
  /// In cs, this message translates to:
  /// **'Domy'**
  String get houses;

  /// No description provided for @aspects.
  ///
  /// In cs, this message translates to:
  /// **'Aspekty'**
  String get aspects;

  /// No description provided for @planetStates.
  ///
  /// In cs, this message translates to:
  /// **'Stav planet'**
  String get planetStates;

  /// No description provided for @compareSystems.
  ///
  /// In cs, this message translates to:
  /// **'Srovnat systémy domů'**
  String get compareSystems;

  /// No description provided for @houseSize.
  ///
  /// In cs, this message translates to:
  /// **'velikost'**
  String get houseSize;

  /// No description provided for @changesHouse.
  ///
  /// In cs, this message translates to:
  /// **'mění dům'**
  String get changesHouse;

  /// No description provided for @noHouses.
  ///
  /// In cs, this message translates to:
  /// **'Čas narození neznámý: horoskop je bez domů, ascendentu a MC.'**
  String get noHouses;

  /// No description provided for @moonUncertain.
  ///
  /// In cs, this message translates to:
  /// **'Měsíc ten den mění znamení; bez času není jisté, ve kterém je.'**
  String get moonUncertain;

  /// No description provided for @polarHouses.
  ///
  /// In cs, this message translates to:
  /// **'Tento systém domů není na této šířce definovaný.'**
  String get polarHouses;

  /// No description provided for @unequalHousesWarning.
  ///
  /// In cs, this message translates to:
  /// **'Na této šířce vycházejí domy Placida velmi nestejné. Zvaž Porphyry.'**
  String get unequalHousesWarning;

  /// No description provided for @readingBySections.
  ///
  /// In cs, this message translates to:
  /// **'Po oddílech'**
  String get readingBySections;

  /// No description provided for @readingByThemes.
  ///
  /// In cs, this message translates to:
  /// **'Podle témat'**
  String get readingByThemes;

  /// No description provided for @sectionSigns.
  ///
  /// In cs, this message translates to:
  /// **'Planety ve znameních'**
  String get sectionSigns;

  /// No description provided for @sectionHouses.
  ///
  /// In cs, this message translates to:
  /// **'Planety v domech'**
  String get sectionHouses;

  /// No description provided for @sectionAspects.
  ///
  /// In cs, this message translates to:
  /// **'Aspekty'**
  String get sectionAspects;

  /// No description provided for @sectionCusps.
  ///
  /// In cs, this message translates to:
  /// **'Znamení na hrotech domů'**
  String get sectionCusps;

  /// No description provided for @sectionEmphasis.
  ///
  /// In cs, this message translates to:
  /// **'Přemíra a nedostatek'**
  String get sectionEmphasis;

  /// No description provided for @textMissing.
  ///
  /// In cs, this message translates to:
  /// **'Text pro toto postavení zatím chybí.'**
  String get textMissing;

  /// No description provided for @shadowTitle.
  ///
  /// In cs, this message translates to:
  /// **'Stinná stránka'**
  String get shadowTitle;

  /// No description provided for @hiddenPassages.
  ///
  /// In cs, this message translates to:
  /// **'Skryto: {count, plural, =1{1 pasáž} few{{count} pasáže} other{{count} pasáží}} ({topics})'**
  String hiddenPassages(int count, Object topics);

  /// No description provided for @helpLink.
  ///
  /// In cs, this message translates to:
  /// **'Potřebuješ si promluvit? Linka první psychické pomoci 116 123, nonstop, zdarma a anonymně'**
  String get helpLink;

  /// No description provided for @traditionNote.
  ///
  /// In cs, this message translates to:
  /// **'Tradiční výklad postavení, ne tvrzení o konkrétní osobě.'**
  String get traditionNote;

  /// No description provided for @shareFull.
  ///
  /// In cs, this message translates to:
  /// **'Sdílet celý výklad (PDF)'**
  String get shareFull;

  /// No description provided for @oneSentence.
  ///
  /// In cs, this message translates to:
  /// **'Jednou větou'**
  String get oneSentence;

  /// No description provided for @overviewLine.
  ///
  /// In cs, this message translates to:
  /// **'Slunce {sun}, Měsíc {moon}{asc}'**
  String overviewLine(Object sun, Object moon, Object asc);

  /// No description provided for @transitsToday.
  ///
  /// In cs, this message translates to:
  /// **'Dnes'**
  String get transitsToday;

  /// No description provided for @transitsTimeline.
  ///
  /// In cs, this message translates to:
  /// **'Den po hodinách'**
  String get transitsTimeline;

  /// No description provided for @transitsCalendar.
  ///
  /// In cs, this message translates to:
  /// **'Kalendář'**
  String get transitsCalendar;

  /// No description provided for @transitsOngoing.
  ///
  /// In cs, this message translates to:
  /// **'Probíhající'**
  String get transitsOngoing;

  /// No description provided for @acute.
  ///
  /// In cs, this message translates to:
  /// **'akutní'**
  String get acute;

  /// No description provided for @now.
  ///
  /// In cs, this message translates to:
  /// **'teď'**
  String get now;

  /// No description provided for @exactAt.
  ///
  /// In cs, this message translates to:
  /// **'přesně {time}'**
  String exactAt(Object time);

  /// No description provided for @phaseApproaching.
  ///
  /// In cs, this message translates to:
  /// **'blíží se'**
  String get phaseApproaching;

  /// No description provided for @phaseExact.
  ///
  /// In cs, this message translates to:
  /// **'přesný'**
  String get phaseExact;

  /// No description provided for @phaseSeparating.
  ///
  /// In cs, this message translates to:
  /// **'odeznívá'**
  String get phaseSeparating;

  /// No description provided for @pass.
  ///
  /// In cs, this message translates to:
  /// **'{n}. průchod'**
  String pass(int n);

  /// No description provided for @passOf.
  ///
  /// In cs, this message translates to:
  /// **'{n}. ze {total}'**
  String passOf(int n, int total);

  /// No description provided for @station.
  ///
  /// In cs, this message translates to:
  /// **'zastávka'**
  String get station;

  /// No description provided for @strength.
  ///
  /// In cs, this message translates to:
  /// **'síla'**
  String get strength;

  /// No description provided for @concurrence.
  ///
  /// In cs, this message translates to:
  /// **'Na týž bod míří víc tranzitů současně.'**
  String get concurrence;

  /// No description provided for @layerBackground.
  ///
  /// In cs, this message translates to:
  /// **'Pozadí (měsíce a roky)'**
  String get layerBackground;

  /// No description provided for @layerWeeks.
  ///
  /// In cs, this message translates to:
  /// **'Týdny'**
  String get layerWeeks;

  /// No description provided for @layerDays.
  ///
  /// In cs, this message translates to:
  /// **'Dny'**
  String get layerDays;

  /// No description provided for @layerHours.
  ///
  /// In cs, this message translates to:
  /// **'Hodiny'**
  String get layerHours;

  /// No description provided for @noTransits.
  ///
  /// In cs, this message translates to:
  /// **'Žádné tranzity v orbu.'**
  String get noTransits;

  /// No description provided for @computing.
  ///
  /// In cs, this message translates to:
  /// **'Počítám…'**
  String get computing;

  /// No description provided for @ingress.
  ///
  /// In cs, this message translates to:
  /// **'{planet} vstupuje do {house}. domu'**
  String ingress(Object planet, int house);

  /// No description provided for @todaySentence.
  ///
  /// In cs, this message translates to:
  /// **'Dnes nejvíc působí {what}.'**
  String todaySentence(Object what);

  /// No description provided for @pickDate.
  ///
  /// In cs, this message translates to:
  /// **'Zvolit den'**
  String get pickDate;

  /// No description provided for @askTrait.
  ///
  /// In cs, this message translates to:
  /// **'Co to vysvětluje?'**
  String get askTrait;

  /// No description provided for @askTraitHint.
  ///
  /// In cs, this message translates to:
  /// **'Napiš rys, např. chaos, žárlivost, vytrvalost'**
  String get askTraitHint;

  /// No description provided for @askEvent.
  ///
  /// In cs, this message translates to:
  /// **'Co se dělo ten den?'**
  String get askEvent;

  /// No description provided for @askEventHint.
  ///
  /// In cs, this message translates to:
  /// **'Popis události'**
  String get askEventHint;

  /// No description provided for @supports.
  ///
  /// In cs, this message translates to:
  /// **'Co to podporuje'**
  String get supports;

  /// No description provided for @speaksAgainst.
  ///
  /// In cs, this message translates to:
  /// **'Co mluví proti'**
  String get speaksAgainst;

  /// No description provided for @didYouMean.
  ///
  /// In cs, this message translates to:
  /// **'Neznám to slovo. Možná hledáš:'**
  String get didYouMean;

  /// No description provided for @noTraitMatch.
  ///
  /// In cs, this message translates to:
  /// **'V horoskopu k tomu není žádné postavení.'**
  String get noTraitMatch;

  /// No description provided for @pickProfile.
  ///
  /// In cs, this message translates to:
  /// **'Vyber profil'**
  String get pickProfile;

  /// No description provided for @dayPercentile.
  ///
  /// In cs, this message translates to:
  /// **'Napětí dne: víc než {p} % dnů života'**
  String dayPercentile(int p);

  /// No description provided for @tense.
  ///
  /// In cs, this message translates to:
  /// **'Napěťové'**
  String get tense;

  /// No description provided for @harmonious.
  ///
  /// In cs, this message translates to:
  /// **'Harmonické'**
  String get harmonious;

  /// No description provided for @connectionsNotProof.
  ///
  /// In cs, this message translates to:
  /// **'Appka ukazuje souvislosti podle tradice, ne důkazy.'**
  String get connectionsNotProof;

  /// No description provided for @settingsFilter.
  ///
  /// In cs, this message translates to:
  /// **'Co nechci vidět'**
  String get settingsFilter;

  /// No description provided for @settingsShadow.
  ///
  /// In cs, this message translates to:
  /// **'Stinné stránky povahy'**
  String get settingsShadow;

  /// No description provided for @gentleMode.
  ///
  /// In cs, this message translates to:
  /// **'Šetrný režim'**
  String get gentleMode;

  /// No description provided for @gentleModeDesc.
  ///
  /// In cs, this message translates to:
  /// **'Skryje všechna těžká témata jedním ťuknutím.'**
  String get gentleModeDesc;

  /// No description provided for @settingsHouses.
  ///
  /// In cs, this message translates to:
  /// **'Výchozí systém domů'**
  String get settingsHouses;

  /// No description provided for @settingsOrbs.
  ///
  /// In cs, this message translates to:
  /// **'Těsné orby (3°)'**
  String get settingsOrbs;

  /// No description provided for @settingsNode.
  ///
  /// In cs, this message translates to:
  /// **'Pravý uzel místo středního'**
  String get settingsNode;

  /// No description provided for @settingsAbout.
  ///
  /// In cs, this message translates to:
  /// **'O appce a zdrojích'**
  String get settingsAbout;

  /// No description provided for @onboardingTitle.
  ///
  /// In cs, this message translates to:
  /// **'Než začneš'**
  String get onboardingTitle;

  /// No description provided for @onboardingBody.
  ///
  /// In cs, this message translates to:
  /// **'Výklad obsahuje i stinné stránky a těžká témata, o kterých tradiční astrologie mluví: nemoc, ztrátu, smrt, krize. Všechno je to tradiční výklad, ne předpověď.'**
  String get onboardingBody;

  /// No description provided for @onboardingGentle.
  ///
  /// In cs, this message translates to:
  /// **'Nebudu ti zobrazovat to, co by ti mohlo ublížit. Ukaž to svému terapeutovi, nedívej se na to o samotě.'**
  String get onboardingGentle;

  /// No description provided for @onboardingShowAll.
  ///
  /// In cs, this message translates to:
  /// **'Zobrazovat všechno'**
  String get onboardingShowAll;

  /// No description provided for @onboardingUseGentle.
  ///
  /// In cs, this message translates to:
  /// **'Zapnout šetrný režim'**
  String get onboardingUseGentle;

  /// No description provided for @onboardingHint.
  ///
  /// In cs, this message translates to:
  /// **'Šetrný režim doporučujeme, pokud procházíš těžkým obdobím. Nastavení jde kdykoli změnit.'**
  String get onboardingHint;

  /// No description provided for @peopleEmpty.
  ///
  /// In cs, this message translates to:
  /// **'Katalog osobností zatím nemá žádný záznam s ověřeným zdrojem. Záznamy přibudou, až bude každý čas narození doložený.'**
  String get peopleEmpty;

  /// No description provided for @reliability.
  ///
  /// In cs, this message translates to:
  /// **'Spolehlivost času'**
  String get reliability;

  /// No description provided for @source.
  ///
  /// In cs, this message translates to:
  /// **'Zdroj'**
  String get source;

  /// No description provided for @glossarySearch.
  ///
  /// In cs, this message translates to:
  /// **'Hledej pojem'**
  String get glossarySearch;

  /// No description provided for @aboutText.
  ///
  /// In cs, this message translates to:
  /// **'Výpočet běží v telefonu, data narození ho neopouštějí. Polohy: VSOP87 a Meeus (balíček astronomia, MIT), Pluto z efemeridy JPL DE440. Místa: GeoNames (CC BY 4.0). Symboly: Noto Sans Symbols (SIL OFL). Texty výkladu jsou vlastní a popisují tradici, ne prokázané souvislosti.'**
  String get aboutText;

  /// No description provided for @bodyName.
  ///
  /// In cs, this message translates to:
  /// **'{body, select, sun{Slunce} moon{Měsíc} mercury{Merkur} venus{Venuše} mars{Mars} jupiter{Jupiter} saturn{Saturn} uranus{Uran} neptune{Neptun} pluto{Pluto} meanNode{Uzel} trueNode{Uzel} asc{Ascendent} mc{MC} other{?}}'**
  String bodyName(String body);

  /// No description provided for @signName.
  ///
  /// In cs, this message translates to:
  /// **'{sign, select, aries{Beran} taurus{Býk} gemini{Blíženci} cancer{Rak} leo{Lev} virgo{Panna} libra{Váhy} scorpio{Štír} sagittarius{Střelec} capricorn{Kozoroh} aquarius{Vodnář} pisces{Ryby} other{?}}'**
  String signName(String sign);

  /// No description provided for @aspectName.
  ///
  /// In cs, this message translates to:
  /// **'{aspect, select, conjunction{konjunkce} sextile{sextil} square{kvadrát} trine{trigon} opposition{opozice} quincunx{kvinkunx} other{?}}'**
  String aspectName(String aspect);

  /// No description provided for @houseSystemName.
  ///
  /// In cs, this message translates to:
  /// **'{system, select, placidus{Placidus} koch{Koch} regiomontanus{Regiomontanus} campanus{Campanus} porphyry{Porphyry} equal{Equal} wholeSign{Celá znamení} meridian{Meridian} morinus{Morinus} other{?}}'**
  String houseSystemName(String system);

  /// No description provided for @dignityName.
  ///
  /// In cs, this message translates to:
  /// **'{d, select, domicile{vládne} exaltation{v povýšení} detriment{ve zničení} fall{v pádu} peregrine{—} other{?}}'**
  String dignityName(String d);

  /// No description provided for @hardTopicName.
  ///
  /// In cs, this message translates to:
  /// **'{t, select, death{smrt} illness{nemoc} mental_crisis{duševní krize} addiction{závislost} violence{násilí} loss{ztráta} ruin{úpadek} other{?}}'**
  String hardTopicName(String t);

  /// No description provided for @themeName.
  ///
  /// In cs, this message translates to:
  /// **'{t, select, character{Povaha} relationships{Vztahy} family{Rodina} work{Práce} money{Peníze} health{Zdraví} growth{Růst} other{Ostatní}}'**
  String themeName(String t);

  /// No description provided for @houseN.
  ///
  /// In cs, this message translates to:
  /// **'{n}. dům'**
  String houseN(int n);

  /// No description provided for @retrogradeShort.
  ///
  /// In cs, this message translates to:
  /// **'R'**
  String get retrogradeShort;

  /// No description provided for @transitTitle.
  ///
  /// In cs, this message translates to:
  /// **'{planet} {aspect} natální {target}'**
  String transitTitle(Object planet, Object aspect, Object target);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['cs'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'cs':
      return AppLocalizationsCs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
