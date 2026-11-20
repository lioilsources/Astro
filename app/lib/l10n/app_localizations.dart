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

  /// No description provided for @patterns.
  ///
  /// In cs, this message translates to:
  /// **'Obrazce aspektů'**
  String get patterns;

  /// No description provided for @noPatterns.
  ///
  /// In cs, this message translates to:
  /// **'V horoskopu není žádný obrazec aspektů.'**
  String get noPatterns;

  /// No description provided for @patternName.
  ///
  /// In cs, this message translates to:
  /// **'{kind, select, grandTrine{Velký trigon} tSquare{T-kvadrát} grandCross{Velký kříž} yod{Jod} kite{Drak} cradle{Kolébka} mysticRectangle{Mystický obdélník} other{?}}'**
  String patternName(String kind);

  /// No description provided for @patternWithQuality.
  ///
  /// In cs, this message translates to:
  /// **'{pattern} ({quality})'**
  String patternWithQuality(Object pattern, Object quality);

  /// No description provided for @elementName.
  ///
  /// In cs, this message translates to:
  /// **'{element, select, fire{oheň} earth{země} air{vzduch} water{voda} other{?}}'**
  String elementName(String element);

  /// No description provided for @modalityName.
  ///
  /// In cs, this message translates to:
  /// **'{m, select, cardinal{kardinální} fixed{pevný} mutable{proměnlivý} other{?}}'**
  String modalityName(String m);

  /// No description provided for @modalityExcess.
  ///
  /// In cs, this message translates to:
  /// **'Přemíra {m, select, cardinal{kardinálních} fixed{pevných} mutable{proměnlivých} other{?}} znamení'**
  String modalityExcess(String m);

  /// No description provided for @modalityLack.
  ///
  /// In cs, this message translates to:
  /// **'Nedostatek {m, select, cardinal{kardinálních} fixed{pevných} mutable{proměnlivých} other{?}} znamení'**
  String modalityLack(String m);

  /// No description provided for @hemisphereEmphasis.
  ///
  /// In cs, this message translates to:
  /// **'{h, select, above{Důraz nad obzorem} below{Důraz pod obzorem} east{Důraz na východní polokouli} west{Důraz na západní polokouli} other{?}}'**
  String hemisphereEmphasis(String h);

  /// No description provided for @unaspectedPlanet.
  ///
  /// In cs, this message translates to:
  /// **'{planet} bez aspektu'**
  String unaspectedPlanet(Object planet);

  /// No description provided for @patternApexTitle.
  ///
  /// In cs, this message translates to:
  /// **'{planet} na vrcholu {kind, select, tSquare{T-kvadrátu} yod{jodu} other{?}}'**
  String patternApexTitle(Object planet, String kind);

  /// No description provided for @patternApex.
  ///
  /// In cs, this message translates to:
  /// **'vrchol: {planets}'**
  String patternApex(Object planets);

  /// No description provided for @textMissing.
  ///
  /// In cs, this message translates to:
  /// **'Text pro toto postavení zatím chybí.'**
  String get textMissing;

  /// No description provided for @timeModeTransits.
  ///
  /// In cs, this message translates to:
  /// **'Tranzity'**
  String get timeModeTransits;

  /// No description provided for @timeModeProgressions.
  ///
  /// In cs, this message translates to:
  /// **'Progrese'**
  String get timeModeProgressions;

  /// No description provided for @timeModeSolar.
  ///
  /// In cs, this message translates to:
  /// **'Solár'**
  String get timeModeSolar;

  /// No description provided for @progressionsAge.
  ///
  /// In cs, this message translates to:
  /// **'Věk {age} let · progresní den {date}'**
  String progressionsAge(Object age, Object date);

  /// No description provided for @progressedMoon.
  ///
  /// In cs, this message translates to:
  /// **'Progresní Měsíc'**
  String get progressedMoon;

  /// No description provided for @progressedSun.
  ///
  /// In cs, this message translates to:
  /// **'Progresní Slunce'**
  String get progressedSun;

  /// No description provided for @progressedPhase.
  ///
  /// In cs, this message translates to:
  /// **'Progresní fáze Měsíce'**
  String get progressedPhase;

  /// No description provided for @progressedAngles.
  ///
  /// In cs, this message translates to:
  /// **'Progresní osy (sluneční oblouk {arc})'**
  String progressedAngles(Object arc);

  /// No description provided for @progressedAspects.
  ///
  /// In cs, this message translates to:
  /// **'Progresní aspekty k natálu (orb 1°)'**
  String get progressedAspects;

  /// No description provided for @progressedAspectsNone.
  ///
  /// In cs, this message translates to:
  /// **'Žádná progresní planeta není do 1° od aspektu k natální poloze.'**
  String get progressedAspectsNone;

  /// No description provided for @progressedAspectTitle.
  ///
  /// In cs, this message translates to:
  /// **'Progresní {planet} {aspect} natální {target}'**
  String progressedAspectTitle(Object planet, Object aspect, Object target);

  /// No description provided for @progressedApplying.
  ///
  /// In cs, this message translates to:
  /// **'{orb} · sbíhá se'**
  String progressedApplying(Object orb);

  /// No description provided for @progressedSeparating.
  ///
  /// In cs, this message translates to:
  /// **'{orb} · rozbíhá se'**
  String progressedSeparating(Object orb);

  /// No description provided for @progressedNoTime.
  ///
  /// In cs, this message translates to:
  /// **'Bez času narození je progresní Měsíc přesný jen asi na ±6° a osy ani domy se nepočítají.'**
  String get progressedNoTime;

  /// No description provided for @lifeTimeline.
  ///
  /// In cs, this message translates to:
  /// **'Časová osa života'**
  String get lifeTimeline;

  /// No description provided for @milestoneMoonSign.
  ///
  /// In cs, this message translates to:
  /// **'Progresní Měsíc vstupuje do znamení {sign}'**
  String milestoneMoonSign(Object sign);

  /// No description provided for @milestoneMoonHouse.
  ///
  /// In cs, this message translates to:
  /// **'Progresní Měsíc vstupuje do {house}. domu'**
  String milestoneMoonHouse(int house);

  /// No description provided for @milestoneSunSign.
  ///
  /// In cs, this message translates to:
  /// **'Progresní Slunce vstupuje do znamení {sign}'**
  String milestoneSunSign(Object sign);

  /// No description provided for @milestoneLunarPhase.
  ///
  /// In cs, this message translates to:
  /// **'Progresní fáze: {phase}'**
  String milestoneLunarPhase(Object phase);

  /// No description provided for @milestoneSolarReturn.
  ///
  /// In cs, this message translates to:
  /// **'Solár {year}'**
  String milestoneSolarReturn(int year);

  /// No description provided for @milestoneAge.
  ///
  /// In cs, this message translates to:
  /// **'{age} let'**
  String milestoneAge(Object age);

  /// No description provided for @timelineMoonHouses.
  ///
  /// In cs, this message translates to:
  /// **'Domy progresního Měsíce'**
  String get timelineMoonHouses;

  /// No description provided for @timelineSolarReturns.
  ///
  /// In cs, this message translates to:
  /// **'Soláry'**
  String get timelineSolarReturns;

  /// No description provided for @solarReturnTitle.
  ///
  /// In cs, this message translates to:
  /// **'Solár {year}'**
  String solarReturnTitle(int year);

  /// No description provided for @solarReturnMoment.
  ///
  /// In cs, this message translates to:
  /// **'Slunce zpět na {lon}: {date}'**
  String solarReturnMoment(Object lon, Object date);

  /// No description provided for @solarPlaceResidence.
  ///
  /// In cs, this message translates to:
  /// **'Bydliště'**
  String get solarPlaceResidence;

  /// No description provided for @solarPlaceBirth.
  ///
  /// In cs, this message translates to:
  /// **'Místo narození'**
  String get solarPlaceBirth;

  /// No description provided for @solarPlace.
  ///
  /// In cs, this message translates to:
  /// **'Místo: {place}'**
  String solarPlace(Object place);

  /// No description provided for @solarAsc.
  ///
  /// In cs, this message translates to:
  /// **'Ascendent soláru'**
  String get solarAsc;

  /// No description provided for @solarSunHouse.
  ///
  /// In cs, this message translates to:
  /// **'Slunce soláru'**
  String get solarSunHouse;

  /// No description provided for @solarOnAngles.
  ///
  /// In cs, this message translates to:
  /// **'Planety na osách soláru (orb 5°)'**
  String get solarOnAngles;

  /// No description provided for @solarNoAngles.
  ///
  /// In cs, this message translates to:
  /// **'Žádná planeta neleží do 5° od osy soláru.'**
  String get solarNoAngles;

  /// No description provided for @solarPlanets.
  ///
  /// In cs, this message translates to:
  /// **'Planety soláru'**
  String get solarPlanets;

  /// No description provided for @solarNoTime.
  ///
  /// In cs, this message translates to:
  /// **'Bez času narození je natální Slunce známé jen asi na ±0,5°, okamžik soláru proto jen asi na ±12 hodin.'**
  String get solarNoTime;

  /// No description provided for @returnAngleName.
  ///
  /// In cs, this message translates to:
  /// **'{angle, select, asc{ascendentu} ic{IC} dsc{descendentu} mc{MC} other{?}}'**
  String returnAngleName(String angle);

  /// No description provided for @planetOnAngle.
  ///
  /// In cs, this message translates to:
  /// **'{planet} na {angle}'**
  String planetOnAngle(Object planet, Object angle);

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

  /// No description provided for @fieldResidence.
  ///
  /// In cs, this message translates to:
  /// **'Místo pobytu'**
  String get fieldResidence;

  /// No description provided for @residenceSameAsBirth.
  ///
  /// In cs, this message translates to:
  /// **'Stejné jako místo narození'**
  String get residenceSameAsBirth;

  /// No description provided for @residenceHint.
  ///
  /// In cs, this message translates to:
  /// **'Kde teď žiješ. Podle něj se počítají planetární hodiny; poloha telefonu se nepoužívá.'**
  String get residenceHint;

  /// No description provided for @settingsVocTraditional.
  ///
  /// In cs, this message translates to:
  /// **'Měsíc bez aspektu: jen tradiční planety (Slunce–Saturn)'**
  String get settingsVocTraditional;

  /// No description provided for @moonAndHours.
  ///
  /// In cs, this message translates to:
  /// **'Měsíc a planetární hodiny'**
  String get moonAndHours;

  /// No description provided for @moonInSign.
  ///
  /// In cs, this message translates to:
  /// **'{sign, select, aries{Měsíc v Beranu} taurus{Měsíc v Býku} gemini{Měsíc v Blížencích} cancer{Měsíc v Raku} leo{Měsíc ve Lvu} virgo{Měsíc v Panně} libra{Měsíc ve Vahách} scorpio{Měsíc ve Štíru} sagittarius{Měsíc ve Střelci} capricorn{Měsíc v Kozorohu} aquarius{Měsíc ve Vodnáři} pisces{Měsíc v Rybách} other{Měsíc}}'**
  String moonInSign(String sign);

  /// No description provided for @moonPhaseName.
  ///
  /// In cs, this message translates to:
  /// **'{phase, select, new{Nov} crescent{Dorůstající srpek} first_quarter{První čtvrť} gibbous{Dorůstající Měsíc} full{Úplněk} disseminating{Couvající Měsíc} last_quarter{Poslední čtvrť} balsamic{Ubývající srpek} other{?}}'**
  String moonPhaseName(String phase);

  /// No description provided for @natalMoonPhaseTitle.
  ///
  /// In cs, this message translates to:
  /// **'Narození ve fázi: {phase}'**
  String natalMoonPhaseTitle(Object phase);

  /// No description provided for @lunationName.
  ///
  /// In cs, this message translates to:
  /// **'{kind, select, newMoon{Nov} firstQuarter{První čtvrť} fullMoon{Úplněk} lastQuarter{Poslední čtvrť} other{?}}'**
  String lunationName(String kind);

  /// No description provided for @lunationInHouse.
  ///
  /// In cs, this message translates to:
  /// **'{lunation} v {house}. domě'**
  String lunationInHouse(int house, Object lunation);

  /// No description provided for @eclipseName.
  ///
  /// In cs, this message translates to:
  /// **'{kind, select, solar{Zatmění Slunce} lunar{Zatmění Měsíce} other{Zatmění}}'**
  String eclipseName(String kind);

  /// No description provided for @eclipseDegree.
  ///
  /// In cs, this message translates to:
  /// **'{degree, select, penumbral{polostínové} partial{částečné} annular{prstencové} hybrid{hybridní} total{úplné} other{}}'**
  String eclipseDegree(String degree);

  /// No description provided for @voidOfCourse.
  ///
  /// In cs, this message translates to:
  /// **'Měsíc bez aspektu'**
  String get voidOfCourse;

  /// No description provided for @voidRange.
  ///
  /// In cs, this message translates to:
  /// **'Měsíc bez aspektu {from} – {to}'**
  String voidRange(Object from, Object to);

  /// No description provided for @voidAfter.
  ///
  /// In cs, this message translates to:
  /// **'po aspektu {aspect}'**
  String voidAfter(Object aspect);

  /// No description provided for @voidEnds.
  ///
  /// In cs, this message translates to:
  /// **'Konec Měsíce bez aspektu'**
  String get voidEnds;

  /// No description provided for @planetGenitive.
  ///
  /// In cs, this message translates to:
  /// **'{body, select, sun{Slunce} moon{Měsíce} mercury{Merkura} venus{Venuše} mars{Marsu} jupiter{Jupitera} saturn{Saturnu} other{?}}'**
  String planetGenitive(String body);

  /// No description provided for @planetaryDay.
  ///
  /// In cs, this message translates to:
  /// **'Den {planet}'**
  String planetaryDay(Object planet);

  /// No description provided for @planetaryHour.
  ///
  /// In cs, this message translates to:
  /// **'Hodina {planet}'**
  String planetaryHour(Object planet);

  /// No description provided for @planetaryHourNumber.
  ///
  /// In cs, this message translates to:
  /// **'{n}. hodina {part}'**
  String planetaryHourNumber(int n, Object part);

  /// No description provided for @partDay.
  ///
  /// In cs, this message translates to:
  /// **'dne'**
  String get partDay;

  /// No description provided for @partNight.
  ///
  /// In cs, this message translates to:
  /// **'noci'**
  String get partNight;

  /// No description provided for @planetaryHours.
  ///
  /// In cs, this message translates to:
  /// **'Planetární hodiny'**
  String get planetaryHours;

  /// No description provided for @sunrise.
  ///
  /// In cs, this message translates to:
  /// **'Východ Slunce'**
  String get sunrise;

  /// No description provided for @sunset.
  ///
  /// In cs, this message translates to:
  /// **'Západ Slunce'**
  String get sunset;

  /// No description provided for @noPlanetaryHours.
  ///
  /// In cs, this message translates to:
  /// **'Slunce tu tento den nevychází nebo nezapadá, planetární hodiny nejsou.'**
  String get noPlanetaryHours;

  /// No description provided for @moonIngressSign.
  ///
  /// In cs, this message translates to:
  /// **'Měsíc vstupuje do znamení {sign}'**
  String moonIngressSign(Object sign);

  /// No description provided for @residenceLabel.
  ///
  /// In cs, this message translates to:
  /// **'Místo pobytu: {place}'**
  String residenceLabel(Object place);

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

  /// No description provided for @electionTitle.
  ///
  /// In cs, this message translates to:
  /// **'Najdi termín'**
  String get electionTitle;

  /// No description provided for @electionIntent.
  ///
  /// In cs, this message translates to:
  /// **'Záměr'**
  String get electionIntent;

  /// No description provided for @electionAboutIntent.
  ///
  /// In cs, this message translates to:
  /// **'O záměru'**
  String get electionAboutIntent;

  /// No description provided for @electionProfile.
  ///
  /// In cs, this message translates to:
  /// **'Profil (místo pobytu)'**
  String get electionProfile;

  /// No description provided for @electionPersonal.
  ///
  /// In cs, this message translates to:
  /// **'Zahrnout můj horoskop'**
  String get electionPersonal;

  /// No description provided for @electionPersonalHint.
  ///
  /// In cs, this message translates to:
  /// **'Přidá napětí tranzitů dne a aspekty Měsíce k tvému Slunci, Měsíci a ascendentu.'**
  String get electionPersonalHint;

  /// No description provided for @electionStart.
  ///
  /// In cs, this message translates to:
  /// **'Od'**
  String get electionStart;

  /// No description provided for @electionDays.
  ///
  /// In cs, this message translates to:
  /// **'Období: {days} dní'**
  String electionDays(int days);

  /// No description provided for @electionHours.
  ///
  /// In cs, this message translates to:
  /// **'Hodiny dne: {from}–{to}'**
  String electionHours(int from, int to);

  /// No description provided for @electionWeekdays.
  ///
  /// In cs, this message translates to:
  /// **'Dny v týdnu'**
  String get electionWeekdays;

  /// No description provided for @weekdayShort.
  ///
  /// In cs, this message translates to:
  /// **'{day, select, 1{Po} 2{Út} 3{St} 4{Čt} 5{Pá} 6{So} 7{Ne} other{?}}'**
  String weekdayShort(String day);

  /// No description provided for @electionSearch.
  ///
  /// In cs, this message translates to:
  /// **'Hledat'**
  String get electionSearch;

  /// No description provided for @electionPlace.
  ///
  /// In cs, this message translates to:
  /// **'Místo: {place}'**
  String electionPlace(Object place);

  /// No description provided for @electionDisclaimer.
  ///
  /// In cs, this message translates to:
  /// **'Okna jsou podle tradičních pravidel nejvhodnější, nejsou zárukou výsledku. Okno s Měsícem bez aspektu se nikdy nenabízí.'**
  String get electionDisclaimer;

  /// No description provided for @electionFound.
  ///
  /// In cs, this message translates to:
  /// **'Podle tradičních pravidel nejvhodnější okna'**
  String get electionFound;

  /// No description provided for @electionNonePassed.
  ///
  /// In cs, this message translates to:
  /// **'V tomto období neprošlo žádné okno. Nejméně špatné je toto, s důvody proti:'**
  String get electionNonePassed;

  /// No description provided for @electionHealthNote.
  ///
  /// In cs, this message translates to:
  /// **'U zdravotních záměrů appka termín nehledá. Tradiční pravidla popisuje slovníček.'**
  String get electionHealthNote;

  /// No description provided for @electionScore.
  ///
  /// In cs, this message translates to:
  /// **'skóre {score}'**
  String electionScore(int score);

  /// No description provided for @electionFor.
  ///
  /// In cs, this message translates to:
  /// **'Pro'**
  String get electionFor;

  /// No description provided for @electionAgainst.
  ///
  /// In cs, this message translates to:
  /// **'Proti'**
  String get electionAgainst;

  /// No description provided for @electionOpenChart.
  ///
  /// In cs, this message translates to:
  /// **'Horoskop okamžiku'**
  String get electionOpenChart;

  /// No description provided for @electionCalendar.
  ///
  /// In cs, this message translates to:
  /// **'Do kalendáře'**
  String get electionCalendar;

  /// No description provided for @electionCalendarAll.
  ///
  /// In cs, this message translates to:
  /// **'Všechna okna do kalendáře'**
  String get electionCalendarAll;

  /// No description provided for @electionEventTitle.
  ///
  /// In cs, this message translates to:
  /// **'Termín: {intent}'**
  String electionEventTitle(Object intent);

  /// No description provided for @electionMomentName.
  ///
  /// In cs, this message translates to:
  /// **'Okamžik {when}'**
  String electionMomentName(Object when);

  /// No description provided for @electionNeedsProfile.
  ///
  /// In cs, this message translates to:
  /// **'Pro místo pobytu potřebuješ aspoň jeden profil.'**
  String get electionNeedsProfile;

  /// No description provided for @electionRule.
  ///
  /// In cs, this message translates to:
  /// **'{rule, select, moon_void{Měsíc bez aspektu} moon_waxing{Dorůstající Měsíc} moon_next_venus{Měsíc míří k Venuši} moon_next_jupiter{Měsíc míří k Jupiteru} venus_angle{Venuše u osy} jupiter_angle{Jupiter u osy} asc_ruler_dignified{Vládce ascendentu silný a přímý} hour_of_intent{Hodina planety záměru} intent_planet_dignified{Planeta záměru silná} benefic_in_intent_house{Dobroděj v domě záměru} personal_moon_harmonious{Měsíc ladí s tvým horoskopem} personal_calm_day{Klidný den v tvých tranzitech} moon_next_mars_hard{Měsíc míří do napětí s Marsem} moon_next_saturn_hard{Měsíc míří do napětí se Saturnem} mars_angle{Mars u osy} saturn_angle{Saturn u osy} intent_planet_retrograde{Planeta záměru retrográdní} intent_planet_fall{Planeta záměru v pádu} intent_planet_detriment{Planeta záměru ve zničení} asc_ruler_bad_house{Vládce ascendentu v 6., 8. nebo 12. domě} asc_ruler_retrograde{Vládce ascendentu retrográdní} eclipse{Blízko zatmění} via_combusta{Měsíc ve spálené cestě} malefic_in_intent_house{Zhoubce v domě záměru} personal_moon_tense{Měsíc v napětí s tvým horoskopem} personal_tension_high{Napjatý den v tvých tranzitech} other{?}}'**
  String electionRule(String rule);

  /// No description provided for @electionIntentName.
  ///
  /// In cs, this message translates to:
  /// **'{intent, select, relationship{Svatba, vztah} contract{Smlouva, podpis, jednání} launch{Zahájení podnikání, projektu} money{Peníze, nákup} move{Stěhování, nemovitost} travel{Cesta} study{Zkouška, studium} application{Žádost, pohovor} surgery{Operace, zákrok} other{?}}'**
  String electionIntentName(String intent);

  /// No description provided for @electionVerdict.
  ///
  /// In cs, this message translates to:
  /// **'{verdict, select, strong{Velmi vhodné} good{Vhodné} weak{Slabé} none{Nejméně špatné} health{Termín se nehledá} other{?}}'**
  String electionVerdict(String verdict);

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

  /// No description provided for @stars.
  ///
  /// In cs, this message translates to:
  /// **'Stálice'**
  String get stars;

  /// No description provided for @sectionStars.
  ///
  /// In cs, this message translates to:
  /// **'Stálice'**
  String get sectionStars;

  /// No description provided for @starsOnWheel.
  ///
  /// In cs, this message translates to:
  /// **'Stálice na kole'**
  String get starsOnWheel;

  /// No description provided for @starsFilterNote.
  ///
  /// In cs, this message translates to:
  /// **'Se zapnutým filtrem zbude u většiny stálic jen základní text, protože tradice o nich mluví hlavně ve stinné vrstvě a v těžkých tématech.'**
  String get starsFilterNote;

  /// No description provided for @starsNone.
  ///
  /// In cs, this message translates to:
  /// **'Žádná planeta ani osa neleží do 1° od některé z 32 stálic.'**
  String get starsNone;

  /// No description provided for @starsAll.
  ///
  /// In cs, this message translates to:
  /// **'Všech 32 stálic'**
  String get starsAll;

  /// No description provided for @starContact.
  ///
  /// In cs, this message translates to:
  /// **'konjunkce: {point} · orb {orb}'**
  String starContact(Object point, Object orb);

  /// No description provided for @starName.
  ///
  /// In cs, this message translates to:
  /// **'{star, select, algol{Algol} alcyone{Alkyone} aldebaran{Aldebaran} rigel{Rigel} bellatrix{Bellatrix} capella{Capella} betelgeuse{Betelgeuze} sirius{Sírius} castor{Castor} pollux{Pollux} procyon{Prokyon} praesepe{Praesepe} alphard{Alphard} regulus{Regulus} denebola{Denebola} vindemiatrix{Vindemiatrix} algorab{Algorab} spica{Spica} arcturus{Arcturus} zubenelgenubi{Zubenelgenubi} zubeneschamali{Zubeneschamali} unukalhai{Unukalhai} acrab{Akrab} antares{Antares} rasalhague{Ras Alhague} vega{Vega} altair{Altair} deneb_algedi{Deneb Algedi} fomalhaut{Fomalhaut} achernar{Achernar} markab{Markab} scheat{Scheat} other{?}}'**
  String starName(String star);

  /// No description provided for @journalTitle.
  ///
  /// In cs, this message translates to:
  /// **'Deník předpovědí'**
  String get journalTitle;

  /// No description provided for @journalRateToday.
  ///
  /// In cs, this message translates to:
  /// **'Ohodnotit dnešek'**
  String get journalRateToday;

  /// No description provided for @journalRateYesterday.
  ///
  /// In cs, this message translates to:
  /// **'Ohodnotit včerejšek'**
  String get journalRateYesterday;

  /// No description provided for @journalChangeRating.
  ///
  /// In cs, this message translates to:
  /// **'Změnit hodnocení'**
  String get journalChangeRating;

  /// No description provided for @journalAddCorrection.
  ///
  /// In cs, this message translates to:
  /// **'Přidat opravu'**
  String get journalAddCorrection;

  /// No description provided for @journalClosedNote.
  ///
  /// In cs, this message translates to:
  /// **'Den je uzavřený. Změna se zapíše jako oprava s odkazem na původní záznam; vyhodnocuje se původní hodnocení.'**
  String get journalClosedNote;

  /// No description provided for @journalOpenUntil.
  ///
  /// In cs, this message translates to:
  /// **'Hodnocení jde měnit do konce dne {day}.'**
  String journalOpenUntil(Object day);

  /// No description provided for @journalRatingLabel.
  ///
  /// In cs, this message translates to:
  /// **'Jaký byl den {day}?'**
  String journalRatingLabel(Object day);

  /// No description provided for @journalRatingValue.
  ///
  /// In cs, this message translates to:
  /// **'{value, select, m2{velmi špatný} m1{spíš špatný} zero{běžný} p1{spíš dobrý} p2{velmi dobrý} other{?}}'**
  String journalRatingValue(String value);

  /// No description provided for @journalTags.
  ///
  /// In cs, this message translates to:
  /// **'Štítky'**
  String get journalTags;

  /// No description provided for @journalTagSearch.
  ///
  /// In cs, this message translates to:
  /// **'Přidat štítek (např. únava)'**
  String get journalTagSearch;

  /// No description provided for @journalNote.
  ///
  /// In cs, this message translates to:
  /// **'Poznámka'**
  String get journalNote;

  /// No description provided for @journalSave.
  ///
  /// In cs, this message translates to:
  /// **'Uložit'**
  String get journalSave;

  /// No description provided for @journalHistory.
  ///
  /// In cs, this message translates to:
  /// **'Ohodnocené dny'**
  String get journalHistory;

  /// No description provided for @journalEmpty.
  ///
  /// In cs, this message translates to:
  /// **'Zatím žádné hodnocení.'**
  String get journalEmpty;

  /// No description provided for @journalSawPrediction.
  ///
  /// In cs, this message translates to:
  /// **'předpověď byla vidět'**
  String get journalSawPrediction;

  /// No description provided for @journalBlindFlag.
  ///
  /// In cs, this message translates to:
  /// **'naslepo'**
  String get journalBlindFlag;

  /// No description provided for @journalCorrectionOf.
  ///
  /// In cs, this message translates to:
  /// **'oprava, původně {value}'**
  String journalCorrectionOf(Object value);

  /// No description provided for @journalTension.
  ///
  /// In cs, this message translates to:
  /// **'napětí {value}'**
  String journalTension(Object value);

  /// No description provided for @journalExport.
  ///
  /// In cs, this message translates to:
  /// **'Exportovat CSV'**
  String get journalExport;

  /// No description provided for @journalBlindTitle.
  ///
  /// In cs, this message translates to:
  /// **'Slepý test'**
  String get journalBlindTitle;

  /// No description provided for @journalBlindOff.
  ///
  /// In cs, this message translates to:
  /// **'Na 90 dní skryje tranzity, dokud dnešek neohodnotíš. Dobrovolné, výchozí vypnuto.'**
  String get journalBlindOff;

  /// No description provided for @journalBlindRunning.
  ///
  /// In cs, this message translates to:
  /// **'Běží do {day}. Tranzity se odemknou po ohodnocení dne.'**
  String journalBlindRunning(Object day);

  /// No description provided for @journalBlindLocked.
  ///
  /// In cs, this message translates to:
  /// **'Slepý test: tranzity se odemknou, až ohodnotíš dnešek.'**
  String get journalBlindLocked;

  /// No description provided for @journalBlindStopConfirm.
  ///
  /// In cs, this message translates to:
  /// **'Ukončit slepý test předčasně? Další hodnocení ponesou příznak, že předpověď byla vidět.'**
  String get journalBlindStopConfirm;

  /// No description provided for @journalEvaluation.
  ///
  /// In cs, this message translates to:
  /// **'Vyhodnocení'**
  String get journalEvaluation;

  /// No description provided for @journalGroupBlind.
  ///
  /// In cs, this message translates to:
  /// **'Hodnocení naslepo'**
  String get journalGroupBlind;

  /// No description provided for @journalGroupSeen.
  ///
  /// In cs, this message translates to:
  /// **'Hodnocení s viditelnou předpovědí'**
  String get journalGroupSeen;

  /// No description provided for @journalTooFew.
  ///
  /// In cs, this message translates to:
  /// **'Zatím málo dat: {n} z {min} ohodnocených dní.'**
  String journalTooFew(Object n, Object min);

  /// No description provided for @journalUndefined.
  ///
  /// In cs, this message translates to:
  /// **'Hodnocení nebo napětí se nemění, souvislost nejde spočítat.'**
  String get journalUndefined;

  /// No description provided for @journalResultExpected.
  ///
  /// In cs, this message translates to:
  /// **'Ve dnech s vyšším napětím hodnotíš den hůř.'**
  String get journalResultExpected;

  /// No description provided for @journalResultOpposite.
  ///
  /// In cs, this message translates to:
  /// **'Ve dnech s vyšším napětím hodnotíš den lépe.'**
  String get journalResultOpposite;

  /// No description provided for @journalResultNone.
  ///
  /// In cs, this message translates to:
  /// **'Souvislost mezi napětím a hodnocením se neukázala.'**
  String get journalResultNone;

  /// No description provided for @journalResultNumbers.
  ///
  /// In cs, this message translates to:
  /// **'Pořadová korelace ρ = {rho}, {size} efekt. Stejnou nebo silnější shodu dalo náhodné přeházení celých týdnů v {p} pokusů z {perms} ({n} dní, {weeks} týdnů).'**
  String journalResultNumbers(
    Object rho,
    Object size,
    Object p,
    Object perms,
    Object n,
    Object weeks,
  );

  /// No description provided for @journalEffect.
  ///
  /// In cs, this message translates to:
  /// **'{size, select, negligible{zanedbatelný} small{malý} moderate{střední} large{velký} other{?}}'**
  String journalEffect(String size);

  /// No description provided for @journalControl.
  ///
  /// In cs, this message translates to:
  /// **'Kontrola cizím horoskopem'**
  String get journalControl;

  /// No description provided for @journalControlResult.
  ///
  /// In cs, this message translates to:
  /// **'Tranzity k {persons} cizím horoskopům z katalogu: stejně dobře nebo lépe sedí {k} z nich (tvoje ρ = {own}, medián cizích ρ = {median}).'**
  String journalControlResult(
    Object persons,
    Object k,
    Object own,
    Object median,
  );

  /// No description provided for @journalControlFew.
  ///
  /// In cs, this message translates to:
  /// **'V katalogu je zatím {n} osob; kontrola potřebuje aspoň {min}.'**
  String journalControlFew(Object n, Object min);

  /// No description provided for @journalControlPartial.
  ///
  /// In cs, this message translates to:
  /// **'Katalog má zatím jen {n} osob místo {want}.'**
  String journalControlPartial(Object n, Object want);

  /// No description provided for @journalControlBetter.
  ///
  /// In cs, this message translates to:
  /// **'Vlastní horoskop sedí líp než cizí.'**
  String get journalControlBetter;

  /// No description provided for @journalControlNotBetter.
  ///
  /// In cs, this message translates to:
  /// **'Vlastní horoskop nesedí líp než cizí.'**
  String get journalControlNotBetter;

  /// No description provided for @journalHypotheses.
  ///
  /// In cs, this message translates to:
  /// **'Vlastní hypotézy'**
  String get journalHypotheses;

  /// No description provided for @journalHypothesisAdd.
  ///
  /// In cs, this message translates to:
  /// **'Zapsat hypotézu'**
  String get journalHypothesisAdd;

  /// No description provided for @journalHypothesisRule.
  ///
  /// In cs, this message translates to:
  /// **'{transit} → {tag}'**
  String journalHypothesisRule(Object transit, Object tag);

  /// No description provided for @journalHypothesisSince.
  ///
  /// In cs, this message translates to:
  /// **'Zapsáno {day}; počítají se jen dny potom.'**
  String journalHypothesisSince(Object day);

  /// No description provided for @journalHypothesisResult.
  ///
  /// In cs, this message translates to:
  /// **'S tranzitem: štítek {a} z {n} dní ({pa}). Bez tranzitu: {b} z {m} dní ({pb}).'**
  String journalHypothesisResult(
    Object a,
    Object n,
    Object pa,
    Object b,
    Object m,
    Object pb,
  );

  /// No description provided for @journalHypothesisFew.
  ///
  /// In cs, this message translates to:
  /// **'Zatím málo dní: potřeba aspoň {min} s tranzitem i bez něj.'**
  String journalHypothesisFew(Object min);

  /// No description provided for @journalHypothesisMore.
  ///
  /// In cs, this message translates to:
  /// **'Štítek se při tranzitu objevuje častěji, než by dala náhoda (p = {p}).'**
  String journalHypothesisMore(Object p);

  /// No description provided for @journalHypothesisNotMore.
  ///
  /// In cs, this message translates to:
  /// **'Štítek se při tranzitu neobjevuje častěji, než by dala náhoda (p = {p}).'**
  String journalHypothesisNotMore(Object p);

  /// No description provided for @journalHypothesisTransiting.
  ///
  /// In cs, this message translates to:
  /// **'Tranzitující planeta'**
  String get journalHypothesisTransiting;

  /// No description provided for @journalHypothesisAspect.
  ///
  /// In cs, this message translates to:
  /// **'Aspekt'**
  String get journalHypothesisAspect;

  /// No description provided for @journalHypothesisTarget.
  ///
  /// In cs, this message translates to:
  /// **'Natální bod'**
  String get journalHypothesisTarget;

  /// No description provided for @journalHypothesisTag.
  ///
  /// In cs, this message translates to:
  /// **'Štítek'**
  String get journalHypothesisTag;

  /// No description provided for @journalHypothesisDelete.
  ///
  /// In cs, this message translates to:
  /// **'Smazat hypotézu'**
  String get journalHypothesisDelete;

  /// No description provided for @journalHypothesisNoTag.
  ///
  /// In cs, this message translates to:
  /// **'Vyber štítek ze slovníku.'**
  String get journalHypothesisNoTag;

  /// No description provided for @journalTextMissing.
  ///
  /// In cs, this message translates to:
  /// **'Text zatím chybí.'**
  String get journalTextMissing;

  /// No description provided for @journalMethod.
  ///
  /// In cs, this message translates to:
  /// **'Jak to funguje'**
  String get journalMethod;

  /// No description provided for @journalReminder.
  ///
  /// In cs, this message translates to:
  /// **'Večerní připomínka deníku'**
  String get journalReminder;

  /// No description provided for @journalReminderDesc.
  ///
  /// In cs, this message translates to:
  /// **'Místní oznámení v telefonu, bez sítě. Čas: {time}.'**
  String journalReminderDesc(Object time);

  /// No description provided for @journalReminderTitle.
  ///
  /// In cs, this message translates to:
  /// **'Deník předpovědí'**
  String get journalReminderTitle;

  /// No description provided for @journalReminderBody.
  ///
  /// In cs, this message translates to:
  /// **'Jaký byl dnešek? Ohodnoť den.'**
  String get journalReminderBody;

  /// No description provided for @journalReminderDenied.
  ///
  /// In cs, this message translates to:
  /// **'Oznámení nejsou povolená. Povol je v nastavení telefonu.'**
  String get journalReminderDenied;

  /// No description provided for @journalErrorNewer.
  ///
  /// In cs, this message translates to:
  /// **'Deník uložila novější verze appky. Aktualizuj appku; data zůstávají beze změny.'**
  String get journalErrorNewer;

  /// No description provided for @synastryTitle.
  ///
  /// In cs, this message translates to:
  /// **'Partnerský horoskop'**
  String get synastryTitle;

  /// No description provided for @synastryIntro.
  ///
  /// In cs, this message translates to:
  /// **'Srovnání dvou uložených profilů: aspekty mezi planetami, planety jedné osoby v domech druhé.'**
  String get synastryIntro;

  /// No description provided for @synastryFirst.
  ///
  /// In cs, this message translates to:
  /// **'První osoba'**
  String get synastryFirst;

  /// No description provided for @synastrySecond.
  ///
  /// In cs, this message translates to:
  /// **'Druhá osoba'**
  String get synastrySecond;

  /// No description provided for @synastryRelationship.
  ///
  /// In cs, this message translates to:
  /// **'Typ vztahu'**
  String get synastryRelationship;

  /// No description provided for @relationshipName.
  ///
  /// In cs, this message translates to:
  /// **'{type, select, partner{Partneři} parentChild{Rodič a dítě} siblings{Sourozenci} friends{Přátelé} colleagues{Kolegové} other{?}}'**
  String relationshipName(String type);

  /// No description provided for @synastryCompare.
  ///
  /// In cs, this message translates to:
  /// **'Porovnat'**
  String get synastryCompare;

  /// No description provided for @synastryNeedTwo.
  ///
  /// In cs, this message translates to:
  /// **'Pro srovnání potřebuješ aspoň dva uložené profily.'**
  String get synastryNeedTwo;

  /// No description provided for @synastrySamePerson.
  ///
  /// In cs, this message translates to:
  /// **'Vyber dvě různé osoby.'**
  String get synastrySamePerson;

  /// No description provided for @tabWheel.
  ///
  /// In cs, this message translates to:
  /// **'Kolo'**
  String get tabWheel;

  /// No description provided for @synastryWheelLegend.
  ///
  /// In cs, this message translates to:
  /// **'Vnitřní kruh: {first} · vnější kruh: {second}'**
  String synastryWheelLegend(Object first, Object second);

  /// No description provided for @synastryAspects.
  ///
  /// In cs, this message translates to:
  /// **'Aspekty mezi vámi'**
  String get synastryAspects;

  /// No description provided for @synastryNoAspects.
  ///
  /// In cs, this message translates to:
  /// **'Mezi horoskopy není žádný aspekt v orbech.'**
  String get synastryNoAspects;

  /// No description provided for @synastryHousesOf.
  ///
  /// In cs, this message translates to:
  /// **'Planety: {owner} · domy: {host}'**
  String synastryHousesOf(Object owner, Object host);

  /// No description provided for @synastryNoHouses.
  ///
  /// In cs, this message translates to:
  /// **'{name}: bez času narození nejsou domy ani osy.'**
  String synastryNoHouses(Object name);

  /// No description provided for @synastryPointOf.
  ///
  /// In cs, this message translates to:
  /// **'{point} ({name})'**
  String synastryPointOf(Object point, Object name);

  /// No description provided for @synastryPartnerTitle.
  ///
  /// In cs, this message translates to:
  /// **'Partnerský dovětek'**
  String get synastryPartnerTitle;

  /// No description provided for @sectionSynastryAspects.
  ///
  /// In cs, this message translates to:
  /// **'Aspekty mezi planetami'**
  String get sectionSynastryAspects;

  /// No description provided for @sectionSynastryPoints.
  ///
  /// In cs, this message translates to:
  /// **'Planety na osách druhého'**
  String get sectionSynastryPoints;

  /// No description provided for @sectionSynastryHouses.
  ///
  /// In cs, this message translates to:
  /// **'Planety v domech druhého'**
  String get sectionSynastryHouses;

  /// No description provided for @twinsTitle.
  ///
  /// In cs, this message translates to:
  /// **'Horoskopy jsou skoro stejné'**
  String get twinsTitle;

  /// No description provided for @twinsBody.
  ///
  /// In cs, this message translates to:
  /// **'Všechny planety leží do 1° od sebe (nejvíc {diff}), takže místo deseti konjunkcí ukazujeme jen to, co se liší. Narození dělí {minutes} min.'**
  String twinsBody(Object diff, Object minutes);

  /// No description provided for @twinsAxes.
  ///
  /// In cs, this message translates to:
  /// **'Ascendent se liší o {asc}, MC o {mc}.'**
  String twinsAxes(Object asc, Object mc);

  /// No description provided for @twinsCusps.
  ///
  /// In cs, this message translates to:
  /// **'Hroty domů se liší o {min} až {max}.'**
  String twinsCusps(Object min, Object max);

  /// No description provided for @twinsNoTime.
  ///
  /// In cs, this message translates to:
  /// **'Bez času narození nejde říct, jak se liší osy a domy.'**
  String get twinsNoTime;

  /// No description provided for @twinsHouseChange.
  ///
  /// In cs, this message translates to:
  /// **'{planet}: {from}. dům → {to}. dům'**
  String twinsHouseChange(Object planet, Object from, Object to);

  /// No description provided for @twinsNoHouseChange.
  ///
  /// In cs, this message translates to:
  /// **'Všechny planety zůstávají ve stejných domech.'**
  String get twinsNoHouseChange;

  /// No description provided for @twinsGlossary.
  ///
  /// In cs, this message translates to:
  /// **'Proč jsou dvojčata různá'**
  String get twinsGlossary;

  /// No description provided for @synastryPairTitle.
  ///
  /// In cs, this message translates to:
  /// **'{first} a {second}'**
  String synastryPairTitle(Object first, Object second);

  /// No description provided for @horaryMode.
  ///
  /// In cs, this message translates to:
  /// **'Horární'**
  String get horaryMode;

  /// No description provided for @horaryIntro.
  ///
  /// In cs, this message translates to:
  /// **'Horoskop se staví na okamžik, kdy otázku potvrdíš. Ptej se na jednu konkrétní věc a na každou jen jednou.'**
  String get horaryIntro;

  /// No description provided for @horaryAbout.
  ///
  /// In cs, this message translates to:
  /// **'Jak se horární otázka čte'**
  String get horaryAbout;

  /// No description provided for @horaryAboutHealth.
  ///
  /// In cs, this message translates to:
  /// **'Zdraví, smrt a těhotenství v horární tradici'**
  String get horaryAboutHealth;

  /// No description provided for @horaryQuestion.
  ///
  /// In cs, this message translates to:
  /// **'Tvoje otázka'**
  String get horaryQuestion;

  /// No description provided for @horaryQuestionHint.
  ///
  /// In cs, this message translates to:
  /// **'Jen pro tebe. Appka text nečte, ukládá ho šifrovaně v telefonu.'**
  String get horaryQuestionHint;

  /// No description provided for @horaryTopic.
  ///
  /// In cs, this message translates to:
  /// **'Téma'**
  String get horaryTopic;

  /// No description provided for @horaryPerson.
  ///
  /// In cs, this message translates to:
  /// **'O kom je otázka'**
  String get horaryPerson;

  /// No description provided for @horaryHouseUsed.
  ///
  /// In cs, this message translates to:
  /// **'Dům věci: {house}.'**
  String horaryHouseUsed(int house);

  /// No description provided for @horaryHouseShort.
  ///
  /// In cs, this message translates to:
  /// **'{house}. dům'**
  String horaryHouseShort(int house);

  /// No description provided for @horaryAsk.
  ///
  /// In cs, this message translates to:
  /// **'Potvrdit otázku'**
  String get horaryAsk;

  /// No description provided for @horaryMomentNote.
  ///
  /// In cs, this message translates to:
  /// **'Okamžikem otázky je chvíle potvrzení, místem tvé místo pobytu z profilu.'**
  String get horaryMomentNote;

  /// No description provided for @horaryNoVerdict.
  ///
  /// In cs, this message translates to:
  /// **'U otázek na zdraví, smrt a těhotenství appka verdikt nedává. Tradiční pravidla popisuje slovníček.'**
  String get horaryNoVerdict;

  /// No description provided for @horaryNoVerdictShort.
  ///
  /// In cs, this message translates to:
  /// **'bez verdiktu'**
  String get horaryNoVerdictShort;

  /// No description provided for @horaryRepeatTitle.
  ///
  /// In cs, this message translates to:
  /// **'Stejné téma znovu'**
  String get horaryRepeatTitle;

  /// No description provided for @horaryRepeatBody.
  ///
  /// In cs, this message translates to:
  /// **'Na stejné téma padla otázka {when}. Tradice druhý pokus do 24 hodin nebere; platí první horoskop.'**
  String horaryRepeatBody(Object when);

  /// No description provided for @horaryShowFirst.
  ///
  /// In cs, this message translates to:
  /// **'Ukázat první horoskop'**
  String get horaryShowFirst;

  /// No description provided for @horaryMoment.
  ///
  /// In cs, this message translates to:
  /// **'Okamžik otázky: {when}, {place}'**
  String horaryMoment(Object when, Object place);

  /// No description provided for @horaryVerdictLine.
  ///
  /// In cs, this message translates to:
  /// **'Podle tradičních pravidel vychází: {verdict}'**
  String horaryVerdictLine(Object verdict);

  /// No description provided for @horaryVerdictName.
  ///
  /// In cs, this message translates to:
  /// **'{verdict, select, yes{ano} yes_difficult{ano, ale s potížemi} no{ne} past{už je to pryč} nothing{nic z toho nebude} unclear{nelze říct} other{?}}'**
  String horaryVerdictName(String verdict);

  /// No description provided for @horaryDisclaimer.
  ///
  /// In cs, this message translates to:
  /// **'Výsledek čte horoskop podle pravidel 17. století. Není to předpověď ani rada.'**
  String get horaryDisclaimer;

  /// No description provided for @horaryTestimony.
  ///
  /// In cs, this message translates to:
  /// **'{rule, select, perfection_conjunction{Ukazatelé se spojí} perfection_sextile{Dokonání sextilem} perfection_trine{Dokonání trigonem} perfection_square{Dokonání kvadrátem} perfection_opposition{Dokonání opozicí} moon_perfection{Měsíc dojde k ukazateli věci} translation{Přenos světla} collection{Sběr světla} reception{Přijetí} mutual_reception{Vzájemné přijetí} querent_strong{Tvůj ukazatel je silný} quesited_strong{Ukazatel věci je silný} quesited_in_first{Ukazatel věci v domě tazatele} querent_in_quesited_house{Tvůj ukazatel v domě věci} natural_perfection{Přirozený ukazatel se připojí} separating{Ukazatelé se rozcházejí} no_aspect{Ukazatelé se nesetkají} prohibition{Zábrana} frustration{Zmaření} refranation{Ústup} combustion{Spálení ukazatele} hard_without_reception{Napětí bez přijetí} querent_weak{Tvůj ukazatel je slabý} quesited_weak{Ukazatel věci je slabý} querent_retrograde{Tvůj ukazatel couvá} quesited_retrograde{Ukazatel věci couvá} other{?}}'**
  String horaryTestimony(String rule);

  /// No description provided for @horaryConsiderations.
  ///
  /// In cs, this message translates to:
  /// **'Výhrady před výkladem'**
  String get horaryConsiderations;

  /// No description provided for @horaryConsiderationNote.
  ///
  /// In cs, this message translates to:
  /// **'Výhrady výklad neblokují. Tradice jimi upozorňuje, že horoskop nemusí být k otázce způsobilý.'**
  String get horaryConsiderationNote;

  /// No description provided for @horaryConsiderationsNone.
  ///
  /// In cs, this message translates to:
  /// **'Žádné výhrady.'**
  String get horaryConsiderationsNone;

  /// No description provided for @horaryConsideration.
  ///
  /// In cs, this message translates to:
  /// **'{rule, select, asc_early{Ascendent v prvních stupních znamení} asc_late{Ascendent v posledních stupních znamení} moon_void{Měsíc bez aspektu} via_combusta{Měsíc ve spálené cestě} saturn_1_7{Saturn v 1. nebo 7. domě} hour_ruler{Vládce hodiny nesouhlasí s ascendentem} other{?}}'**
  String horaryConsideration(String rule);

  /// No description provided for @horaryTimingTitle.
  ///
  /// In cs, this message translates to:
  /// **'Tradiční odhad času'**
  String get horaryTimingTitle;

  /// No description provided for @horaryTimingLine.
  ///
  /// In cs, this message translates to:
  /// **'Do dokonání zbývá {degrees}°, podle tradice tedy asi {unit}. Je to odhad, ne termín.'**
  String horaryTimingLine(Object degrees, Object unit);

  /// No description provided for @horaryTimingUnknown.
  ///
  /// In cs, this message translates to:
  /// **'Pro toto postavení tradice jednotku času neurčuje.'**
  String get horaryTimingUnknown;

  /// No description provided for @horaryDays.
  ///
  /// In cs, this message translates to:
  /// **'{count, plural, =1{1 den} few{{count} dny} other{{count} dní}}'**
  String horaryDays(int count);

  /// No description provided for @horaryWeeks.
  ///
  /// In cs, this message translates to:
  /// **'{count, plural, =1{1 týden} few{{count} týdny} other{{count} týdnů}}'**
  String horaryWeeks(int count);

  /// No description provided for @horaryMonths.
  ///
  /// In cs, this message translates to:
  /// **'{count, plural, =1{1 měsíc} few{{count} měsíce} other{{count} měsíců}}'**
  String horaryMonths(int count);

  /// No description provided for @horaryYears.
  ///
  /// In cs, this message translates to:
  /// **'{count, plural, =1{1 rok} few{{count} roky} other{{count} let}}'**
  String horaryYears(int count);

  /// No description provided for @horaryLostTitle.
  ///
  /// In cs, this message translates to:
  /// **'Ztracená věc'**
  String get horaryLostTitle;

  /// No description provided for @horaryLostLine.
  ///
  /// In cs, this message translates to:
  /// **'Podle znamení ({sign}) směr {bySign}, podle {house}. domu směr {byHouse}.'**
  String horaryLostLine(Object bySign, Object sign, Object byHouse, int house);

  /// No description provided for @horarySignificators.
  ///
  /// In cs, this message translates to:
  /// **'Ukazatelé'**
  String get horarySignificators;

  /// No description provided for @horaryQuerent.
  ///
  /// In cs, this message translates to:
  /// **'Tazatel ({house}. dům)'**
  String horaryQuerent(int house);

  /// No description provided for @horaryCoQuerent.
  ///
  /// In cs, this message translates to:
  /// **'Měsíc, druhý ukazatel tazatele'**
  String get horaryCoQuerent;

  /// No description provided for @horaryQuesited.
  ///
  /// In cs, this message translates to:
  /// **'Věc ({house}. dům)'**
  String horaryQuesited(int house);

  /// No description provided for @horaryNatural.
  ///
  /// In cs, this message translates to:
  /// **'Přirozený ukazatel věci'**
  String get horaryNatural;

  /// No description provided for @horaryStrength.
  ///
  /// In cs, this message translates to:
  /// **'síla {total} (bytostná {essential}, nahodilá {accidental})'**
  String horaryStrength(int total, int essential, int accidental);

  /// No description provided for @horaryLogTitle.
  ///
  /// In cs, this message translates to:
  /// **'Deník otázek'**
  String get horaryLogTitle;

  /// No description provided for @horaryLogEmpty.
  ///
  /// In cs, this message translates to:
  /// **'Zatím žádné otázky.'**
  String get horaryLogEmpty;

  /// No description provided for @horaryFollowUp.
  ///
  /// In cs, this message translates to:
  /// **'Jak to dopadlo?'**
  String get horaryFollowUp;

  /// No description provided for @horaryOutcomeName.
  ///
  /// In cs, this message translates to:
  /// **'{outcome, select, yes{Ano} no{Ne} other{Jinak, nevím}}'**
  String horaryOutcomeName(String outcome);

  /// No description provided for @horaryOutcomeSet.
  ///
  /// In cs, this message translates to:
  /// **'Jak to dopadlo: {outcome}'**
  String horaryOutcomeSet(Object outcome);

  /// No description provided for @horaryHitRate.
  ///
  /// In cs, this message translates to:
  /// **'Zásahy: {rate} % z {n} uzavřených otázek s odpovědí ano nebo ne. Kdyby appka vždycky řekla ano: {yes} %, vždycky ne: {no} %.'**
  String horaryHitRate(int rate, int n, int yes, int no);

  /// No description provided for @horaryHitRateTooFew.
  ///
  /// In cs, this message translates to:
  /// **'Podíl zásahů appka ukáže od {min} uzavřených otázek s odpovědí ano nebo ne. Uzavřených otázek: {n}.'**
  String horaryHitRateTooFew(int min, int n);

  /// No description provided for @horaryPdf.
  ///
  /// In cs, this message translates to:
  /// **'Export do PDF'**
  String get horaryPdf;

  /// No description provided for @horaryPdfTitle.
  ///
  /// In cs, this message translates to:
  /// **'Export otázky do PDF'**
  String get horaryPdfTitle;

  /// No description provided for @horaryPdfIncludeText.
  ///
  /// In cs, this message translates to:
  /// **'Přidat do PDF i text otázky'**
  String get horaryPdfIncludeText;

  /// No description provided for @horaryTopicName.
  ///
  /// In cs, this message translates to:
  /// **'{topic, select, money{Peníze} property{Majetek} lost_object{Ztracená věc} siblings{Sourozenci} short_trip{Krátká cesta} message{Zpráva, dopis} home{Domov} real_estate{Nemovitost} parents{Rodiče} children{Děti} love{Láska} game{Hra, sázka} daily_work{Každodenní práce} employees{Podřízení} pet{Domácí zvíře} partner{Partner, partnerka} contract{Smlouva} dispute{Spor} opponent{Protivník} debts{Dluhy} inheritance{Dědictví} others_money{Cizí peníze} long_trip{Dálková cesta} study{Studium} law{Úřady a právo} career{Kariéra, místo} position{Postavení, funkce} superior{Nadřízený} friends{Přátelé} wish{Přání} hidden{Skryté věci} secret_enemies{Tajní nepřátelé} health{Zdraví, nemoc} death{Smrt} pregnancy{Těhotenství} other{?}}'**
  String horaryTopicName(String topic);

  /// No description provided for @horaryPersonName.
  ///
  /// In cs, this message translates to:
  /// **'{person, select, self{Já} sibling{Sourozenec} child{Dítě} partner{Partner, partnerka} father{Otec} mother{Matka} friend{Přítel, přítelkyně} other{?}}'**
  String horaryPersonName(String person);

  /// No description provided for @horaryDirection.
  ///
  /// In cs, this message translates to:
  /// **'{dir, select, east{východ} east_by_north{východ k severu} east_by_south{východ k jihu} west{západ} west_by_south{západ k jihu} west_by_north{západ k severu} north{sever} north_by_east{sever k východu} north_by_west{sever k západu} south{jih} south_by_east{jih k východu} south_by_west{jih k západu} northeast_by_east{severovýchod k východu} north_northeast{severoseverovýchod} northwest_by_north{severozápad k severu} west_northwest{západoseverozápad} southwest_by_south{jihozápad k jihu} south_southwest{jihojihozápad} southeast_by_south{jihovýchod k jihu} east_southeast{východojihovýchod} other{?}}'**
  String horaryDirection(String dir);
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
