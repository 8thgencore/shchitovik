import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'common_translations_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of CommonTranslationsLocalizations
/// returned by `CommonTranslationsLocalizations.of(context)`.
///
/// Applications need to include `CommonTranslationsLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/common_translations_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: CommonTranslationsLocalizations.localizationsDelegates,
///   supportedLocales: CommonTranslationsLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the CommonTranslationsLocalizations.supportedLocales
/// property.
abstract class CommonTranslationsLocalizations {
  CommonTranslationsLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static CommonTranslationsLocalizations of(BuildContext context) {
    return Localizations.of<CommonTranslationsLocalizations>(
      context,
      CommonTranslationsLocalizations,
    )!;
  }

  static const LocalizationsDelegate<CommonTranslationsLocalizations> delegate =
      _CommonTranslationsLocalizationsDelegate();

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
  static const List<Locale> supportedLocales = <Locale>[Locale('ru')];

  /// No description provided for @appTitle.
  ///
  /// In ru, this message translates to:
  /// **'Щитовик'**
  String get appTitle;

  /// No description provided for @ok.
  ///
  /// In ru, this message translates to:
  /// **'ОК'**
  String get ok;

  /// No description provided for @cancel.
  ///
  /// In ru, this message translates to:
  /// **'Отмена'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In ru, this message translates to:
  /// **'Подтвердить'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In ru, this message translates to:
  /// **'Повторить'**
  String get retry;

  /// No description provided for @moreActions.
  ///
  /// In ru, this message translates to:
  /// **'Ещё'**
  String get moreActions;

  /// No description provided for @initializationFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось запустить приложение'**
  String get initializationFailed;

  /// No description provided for @projectsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Проекты'**
  String get projectsTitle;

  /// No description provided for @projectsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Проектов пока нет'**
  String get projectsEmpty;

  /// No description provided for @settingsTitle.
  ///
  /// In ru, this message translates to:
  /// **'Настройки'**
  String get settingsTitle;

  /// No description provided for @themeModeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Тема'**
  String get themeModeTitle;

  /// No description provided for @themeModeSystem.
  ///
  /// In ru, this message translates to:
  /// **'Как в системе'**
  String get themeModeSystem;

  /// No description provided for @themeModeLight.
  ///
  /// In ru, this message translates to:
  /// **'Светлая'**
  String get themeModeLight;

  /// No description provided for @themeModeDark.
  ///
  /// In ru, this message translates to:
  /// **'Тёмная'**
  String get themeModeDark;

  /// No description provided for @estimateDisclaimer.
  ///
  /// In ru, this message translates to:
  /// **'Ориентировочный расчёт. Не заменяет проект, выполненный квалифицированным специалистом.'**
  String get estimateDisclaimer;

  /// No description provided for @delete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить'**
  String get save;

  /// No description provided for @close.
  ///
  /// In ru, this message translates to:
  /// **'Закрыть'**
  String get close;

  /// No description provided for @auto.
  ///
  /// In ru, this message translates to:
  /// **'Авто'**
  String get auto;

  /// No description provided for @yes.
  ///
  /// In ru, this message translates to:
  /// **'Да'**
  String get yes;

  /// No description provided for @no.
  ///
  /// In ru, this message translates to:
  /// **'Нет'**
  String get no;

  /// No description provided for @reset.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить'**
  String get reset;

  /// No description provided for @notSet.
  ///
  /// In ru, this message translates to:
  /// **'не задано'**
  String get notSet;

  /// No description provided for @projectsCreate.
  ///
  /// In ru, this message translates to:
  /// **'Создать проект'**
  String get projectsCreate;

  /// No description provided for @projectsImport.
  ///
  /// In ru, this message translates to:
  /// **'Импортировать проект'**
  String get projectsImport;

  /// No description provided for @projectsImportFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось импортировать проект: {message}'**
  String projectsImportFailed(String message);

  /// No description provided for @projectsImported.
  ///
  /// In ru, this message translates to:
  /// **'Проект «{name}» импортирован'**
  String projectsImported(String name);

  /// No description provided for @projectsDemoTitle.
  ///
  /// In ru, this message translates to:
  /// **'Или начните с примера'**
  String get projectsDemoTitle;

  /// No description provided for @projectsDemoOneRoom.
  ///
  /// In ru, this message translates to:
  /// **'1-комнатная квартира'**
  String get projectsDemoOneRoom;

  /// No description provided for @projectsDemoThreeRoom.
  ///
  /// In ru, this message translates to:
  /// **'3-комнатная квартира'**
  String get projectsDemoThreeRoom;

  /// No description provided for @projectsDemoHouse.
  ///
  /// In ru, this message translates to:
  /// **'Частный дом'**
  String get projectsDemoHouse;

  /// No description provided for @projectsUpdated.
  ///
  /// In ru, this message translates to:
  /// **'изменён {date}'**
  String projectsUpdated(String date);

  /// No description provided for @projectDuplicate.
  ///
  /// In ru, this message translates to:
  /// **'Дублировать'**
  String get projectDuplicate;

  /// No description provided for @projectExport.
  ///
  /// In ru, this message translates to:
  /// **'Экспортировать проект'**
  String get projectExport;

  /// No description provided for @projectDeleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить проект «{name}»?'**
  String projectDeleteTitle(String name);

  /// No description provided for @projectDeleteMessage.
  ///
  /// In ru, this message translates to:
  /// **'Проект, его помещения, линии и смета будут удалены без возможности восстановления.'**
  String get projectDeleteMessage;

  /// No description provided for @projectNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Проект не найден'**
  String get projectNotFound;

  /// No description provided for @createProjectTitle.
  ///
  /// In ru, this message translates to:
  /// **'Новый проект'**
  String get createProjectTitle;

  /// No description provided for @createProjectName.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get createProjectName;

  /// No description provided for @createProjectDefaultName.
  ///
  /// In ru, this message translates to:
  /// **'Мой проект'**
  String get createProjectDefaultName;

  /// No description provided for @objectTypeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Тип объекта'**
  String get objectTypeTitle;

  /// No description provided for @supplyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Ввод'**
  String get supplyTitle;

  /// No description provided for @supplySingle.
  ///
  /// In ru, this message translates to:
  /// **'1 фаза'**
  String get supplySingle;

  /// No description provided for @supplyThree.
  ///
  /// In ru, this message translates to:
  /// **'3 фазы'**
  String get supplyThree;

  /// No description provided for @create.
  ///
  /// In ru, this message translates to:
  /// **'Создать'**
  String get create;

  /// No description provided for @tabSetup.
  ///
  /// In ru, this message translates to:
  /// **'Объект'**
  String get tabSetup;

  /// No description provided for @tabRooms.
  ///
  /// In ru, this message translates to:
  /// **'Помещения'**
  String get tabRooms;

  /// No description provided for @tabCircuits.
  ///
  /// In ru, this message translates to:
  /// **'Линии'**
  String get tabCircuits;

  /// No description provided for @tabEstimate.
  ///
  /// In ru, this message translates to:
  /// **'Смета'**
  String get tabEstimate;

  /// No description provided for @reportPdf.
  ///
  /// In ru, this message translates to:
  /// **'Сохранить PDF'**
  String get reportPdf;

  /// No description provided for @reportInProgress.
  ///
  /// In ru, this message translates to:
  /// **'Формируем PDF…'**
  String get reportInProgress;

  /// No description provided for @reportFailed.
  ///
  /// In ru, this message translates to:
  /// **'Не удалось сформировать отчёт. Повторите попытку; если ошибка повторится, скопируйте подробности для поддержки.'**
  String get reportFailed;

  /// No description provided for @interfaceModeTitle.
  ///
  /// In ru, this message translates to:
  /// **'Режим'**
  String get interfaceModeTitle;

  /// No description provided for @interfaceModeSimple.
  ///
  /// In ru, this message translates to:
  /// **'Простой'**
  String get interfaceModeSimple;

  /// No description provided for @interfaceModeExpert.
  ///
  /// In ru, this message translates to:
  /// **'Экспертный'**
  String get interfaceModeExpert;

  /// No description provided for @interfaceModeHint.
  ///
  /// In ru, this message translates to:
  /// **'В экспертном режиме доступны все параметры расчёта и ручная правка линий.'**
  String get interfaceModeHint;

  /// No description provided for @setupGeneral.
  ///
  /// In ru, this message translates to:
  /// **'Общее'**
  String get setupGeneral;

  /// No description provided for @setupSupply.
  ///
  /// In ru, this message translates to:
  /// **'Ввод и сеть'**
  String get setupSupply;

  /// No description provided for @setupCable.
  ///
  /// In ru, this message translates to:
  /// **'Кабель по умолчанию'**
  String get setupCable;

  /// No description provided for @setupProtection.
  ///
  /// In ru, this message translates to:
  /// **'Защита'**
  String get setupProtection;

  /// No description provided for @setupName.
  ///
  /// In ru, this message translates to:
  /// **'Название проекта'**
  String get setupName;

  /// No description provided for @setupNote.
  ///
  /// In ru, this message translates to:
  /// **'Заметка'**
  String get setupNote;

  /// No description provided for @setupVoltage.
  ///
  /// In ru, this message translates to:
  /// **'Номинальное напряжение'**
  String get setupVoltage;

  /// No description provided for @setupAllowedPower.
  ///
  /// In ru, this message translates to:
  /// **'Разрешённая мощность, кВт'**
  String get setupAllowedPower;

  /// No description provided for @setupAllowedPowerHint.
  ///
  /// In ru, this message translates to:
  /// **'Из технических условий на присоединение'**
  String get setupAllowedPowerHint;

  /// No description provided for @setupIncomerBreaker.
  ///
  /// In ru, this message translates to:
  /// **'Существующий вводной автомат, А'**
  String get setupIncomerBreaker;

  /// No description provided for @setupExternalLoop.
  ///
  /// In ru, this message translates to:
  /// **'Сопротивление петли «фаза — нуль» до щита, Ом'**
  String get setupExternalLoop;

  /// No description provided for @setupExternalLoopHint.
  ///
  /// In ru, this message translates to:
  /// **'По замеру или от сетевой организации; без него проверка КЗ — с допущением'**
  String get setupExternalLoopHint;

  /// No description provided for @setupCookingFuel.
  ///
  /// In ru, this message translates to:
  /// **'Плита'**
  String get setupCookingFuel;

  /// No description provided for @cookingFuelNaturalGas.
  ///
  /// In ru, this message translates to:
  /// **'Газовая'**
  String get cookingFuelNaturalGas;

  /// No description provided for @cookingFuelLiquefied.
  ///
  /// In ru, this message translates to:
  /// **'Сжиженный газ / твёрдое топливо'**
  String get cookingFuelLiquefied;

  /// No description provided for @cookingFuelElectric.
  ///
  /// In ru, this message translates to:
  /// **'Электрическая'**
  String get cookingFuelElectric;

  /// No description provided for @setupCommercialProfile.
  ///
  /// In ru, this message translates to:
  /// **'Профиль помещения'**
  String get setupCommercialProfile;

  /// No description provided for @profileOffice.
  ///
  /// In ru, this message translates to:
  /// **'Офис'**
  String get profileOffice;

  /// No description provided for @profileShop.
  ///
  /// In ru, this message translates to:
  /// **'Магазин'**
  String get profileShop;

  /// No description provided for @profileCatering.
  ///
  /// In ru, this message translates to:
  /// **'Общепит'**
  String get profileCatering;

  /// No description provided for @profileServices.
  ///
  /// In ru, this message translates to:
  /// **'Салон, мастерская услуг'**
  String get profileServices;

  /// No description provided for @profileWorkshop.
  ///
  /// In ru, this message translates to:
  /// **'Мастерская со станками'**
  String get profileWorkshop;

  /// No description provided for @setupRcdStrategy.
  ///
  /// In ru, this message translates to:
  /// **'Устройства защитного отключения'**
  String get setupRcdStrategy;

  /// No description provided for @rcdStrategyRcbo.
  ///
  /// In ru, this message translates to:
  /// **'Дифавтомат на каждую линию'**
  String get rcdStrategyRcbo;

  /// No description provided for @rcdStrategyRcd.
  ///
  /// In ru, this message translates to:
  /// **'Автомат + УЗО на каждую линию'**
  String get rcdStrategyRcd;

  /// No description provided for @rcdStrategyGrouped.
  ///
  /// In ru, this message translates to:
  /// **'Общие УЗО на группы линий'**
  String get rcdStrategyGrouped;

  /// No description provided for @setupFireRcd.
  ///
  /// In ru, this message translates to:
  /// **'Противопожарное УЗО на вводе'**
  String get setupFireRcd;

  /// No description provided for @setupMaterial.
  ///
  /// In ru, this message translates to:
  /// **'Материал жил'**
  String get setupMaterial;

  /// No description provided for @materialCopper.
  ///
  /// In ru, this message translates to:
  /// **'Медь'**
  String get materialCopper;

  /// No description provided for @materialAluminium.
  ///
  /// In ru, this message translates to:
  /// **'Алюминий'**
  String get materialAluminium;

  /// No description provided for @setupInsulation.
  ///
  /// In ru, this message translates to:
  /// **'Изоляция'**
  String get setupInsulation;

  /// No description provided for @insulationPvc.
  ///
  /// In ru, this message translates to:
  /// **'ПВХ (70 °C)'**
  String get insulationPvc;

  /// No description provided for @insulationXlpe.
  ///
  /// In ru, this message translates to:
  /// **'Сшитый полиэтилен (90 °C)'**
  String get insulationXlpe;

  /// No description provided for @setupMethod.
  ///
  /// In ru, this message translates to:
  /// **'Способ прокладки'**
  String get setupMethod;

  /// No description provided for @setupAmbient.
  ///
  /// In ru, this message translates to:
  /// **'Температура среды, °C'**
  String get setupAmbient;

  /// No description provided for @setupGrouped.
  ///
  /// In ru, this message translates to:
  /// **'Цепей, проложенных вместе'**
  String get setupGrouped;

  /// No description provided for @setupDefaultLength.
  ///
  /// In ru, this message translates to:
  /// **'Длина линии по умолчанию, м'**
  String get setupDefaultLength;

  /// No description provided for @roomsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте помещения — приборы подставятся из типового набора'**
  String get roomsEmpty;

  /// No description provided for @roomsAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить помещение'**
  String get roomsAdd;

  /// No description provided for @roomsAddTitle.
  ///
  /// In ru, this message translates to:
  /// **'Добавить помещение'**
  String get roomsAddTitle;

  /// No description provided for @roomsEmptyRoom.
  ///
  /// In ru, this message translates to:
  /// **'Пустое помещение'**
  String get roomsEmptyRoom;

  /// No description provided for @roomRename.
  ///
  /// In ru, this message translates to:
  /// **'Переименовать'**
  String get roomRename;

  /// No description provided for @roomKind.
  ///
  /// In ru, this message translates to:
  /// **'Тип помещения'**
  String get roomKind;

  /// No description provided for @roomKindStandard.
  ///
  /// In ru, this message translates to:
  /// **'Жилое / обычное'**
  String get roomKindStandard;

  /// No description provided for @roomKindKitchen.
  ///
  /// In ru, this message translates to:
  /// **'Кухня'**
  String get roomKindKitchen;

  /// No description provided for @roomKindBathroom.
  ///
  /// In ru, this message translates to:
  /// **'Ванная, душевая, сауна'**
  String get roomKindBathroom;

  /// No description provided for @roomKindOutdoor.
  ///
  /// In ru, this message translates to:
  /// **'Улица'**
  String get roomKindOutdoor;

  /// No description provided for @roomKindGarage.
  ///
  /// In ru, this message translates to:
  /// **'Гараж, мастерская'**
  String get roomKindGarage;

  /// No description provided for @roomDeleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить помещение «{name}»?'**
  String roomDeleteTitle(String name);

  /// No description provided for @roomDeleteMessage.
  ///
  /// In ru, this message translates to:
  /// **'Вместе с помещением будут удалены его приборы.'**
  String get roomDeleteMessage;

  /// No description provided for @devicesAdd.
  ///
  /// In ru, this message translates to:
  /// **'Добавить прибор'**
  String get devicesAdd;

  /// No description provided for @devicesSearch.
  ///
  /// In ru, this message translates to:
  /// **'Поиск прибора'**
  String get devicesSearch;

  /// No description provided for @deviceCustom.
  ///
  /// In ru, this message translates to:
  /// **'Свой прибор'**
  String get deviceCustom;

  /// No description provided for @deviceName.
  ///
  /// In ru, this message translates to:
  /// **'Название'**
  String get deviceName;

  /// No description provided for @devicePower.
  ///
  /// In ru, this message translates to:
  /// **'Мощность одного, Вт'**
  String get devicePower;

  /// No description provided for @deviceQuantity.
  ///
  /// In ru, this message translates to:
  /// **'Количество'**
  String get deviceQuantity;

  /// No description provided for @devicePhases.
  ///
  /// In ru, this message translates to:
  /// **'Фазы'**
  String get devicePhases;

  /// No description provided for @deviceCosPhi.
  ///
  /// In ru, this message translates to:
  /// **'cos φ'**
  String get deviceCosPhi;

  /// No description provided for @deviceUsageFactor.
  ///
  /// In ru, this message translates to:
  /// **'Коэффициент использования ku'**
  String get deviceUsageFactor;

  /// No description provided for @deviceInrush.
  ///
  /// In ru, this message translates to:
  /// **'Кратность пускового тока'**
  String get deviceInrush;

  /// No description provided for @deviceConnection.
  ///
  /// In ru, this message translates to:
  /// **'Подключение'**
  String get deviceConnection;

  /// No description provided for @connectionSocket.
  ///
  /// In ru, this message translates to:
  /// **'Через розетку'**
  String get connectionSocket;

  /// No description provided for @connectionFixed.
  ///
  /// In ru, this message translates to:
  /// **'Стационарно'**
  String get connectionFixed;

  /// No description provided for @deviceDedicated.
  ///
  /// In ru, this message translates to:
  /// **'Отдельная линия'**
  String get deviceDedicated;

  /// No description provided for @dedicatedRequired.
  ///
  /// In ru, this message translates to:
  /// **'Обязательно'**
  String get dedicatedRequired;

  /// No description provided for @dedicatedRecommended.
  ///
  /// In ru, this message translates to:
  /// **'По умолчанию'**
  String get dedicatedRecommended;

  /// No description provided for @dedicatedNo.
  ///
  /// In ru, this message translates to:
  /// **'Общая группа'**
  String get dedicatedNo;

  /// No description provided for @circuitsEmpty.
  ///
  /// In ru, this message translates to:
  /// **'Линии появятся, когда вы добавите приборы'**
  String get circuitsEmpty;

  /// No description provided for @circuitsInput.
  ///
  /// In ru, this message translates to:
  /// **'Ввод'**
  String get circuitsInput;

  /// No description provided for @circuitsInstalled.
  ///
  /// In ru, this message translates to:
  /// **'Установленная мощность'**
  String get circuitsInstalled;

  /// No description provided for @circuitsByDevices.
  ///
  /// In ru, this message translates to:
  /// **'По приборам (Σ P·ku)'**
  String get circuitsByDevices;

  /// No description provided for @circuitsNormative.
  ///
  /// In ru, this message translates to:
  /// **'Расчётная по СП 256'**
  String get circuitsNormative;

  /// No description provided for @circuitsDesignCurrent.
  ///
  /// In ru, this message translates to:
  /// **'Расчётный ток'**
  String get circuitsDesignCurrent;

  /// No description provided for @circuitsIncomer.
  ///
  /// In ru, this message translates to:
  /// **'Вводной автомат'**
  String get circuitsIncomer;

  /// No description provided for @circuitsFireRcd.
  ///
  /// In ru, this message translates to:
  /// **'УЗО на вводе'**
  String get circuitsFireRcd;

  /// No description provided for @circuitsPhases.
  ///
  /// In ru, this message translates to:
  /// **'Фазы'**
  String get circuitsPhases;

  /// No description provided for @circuitsImbalance.
  ///
  /// In ru, this message translates to:
  /// **'Разница токов фаз'**
  String get circuitsImbalance;

  /// No description provided for @circuitsAssumptions.
  ///
  /// In ru, this message translates to:
  /// **'Допущения расчёта'**
  String get circuitsAssumptions;

  /// No description provided for @circuitsIssues.
  ///
  /// In ru, this message translates to:
  /// **'Замечания'**
  String get circuitsIssues;

  /// No description provided for @circuitStatus.
  ///
  /// In ru, this message translates to:
  /// **'Статус'**
  String get circuitStatus;

  /// No description provided for @circuitValues.
  ///
  /// In ru, this message translates to:
  /// **'Расчёт'**
  String get circuitValues;

  /// No description provided for @circuitChecks.
  ///
  /// In ru, this message translates to:
  /// **'Проверки'**
  String get circuitChecks;

  /// No description provided for @circuitRcdReasons.
  ///
  /// In ru, this message translates to:
  /// **'Почему нужно УЗО'**
  String get circuitRcdReasons;

  /// No description provided for @circuitSettings.
  ///
  /// In ru, this message translates to:
  /// **'Параметры линии'**
  String get circuitSettings;

  /// No description provided for @circuitExpert.
  ///
  /// In ru, this message translates to:
  /// **'Ручные изменения'**
  String get circuitExpert;

  /// No description provided for @circuitLength.
  ///
  /// In ru, this message translates to:
  /// **'Длина, м'**
  String get circuitLength;

  /// No description provided for @circuitSection.
  ///
  /// In ru, this message translates to:
  /// **'Сечение, мм²'**
  String get circuitSection;

  /// No description provided for @circuitBreaker.
  ///
  /// In ru, this message translates to:
  /// **'Номинал автомата, А'**
  String get circuitBreaker;

  /// No description provided for @circuitCurve.
  ///
  /// In ru, this message translates to:
  /// **'Характеристика'**
  String get circuitCurve;

  /// No description provided for @circuitProtection.
  ///
  /// In ru, this message translates to:
  /// **'Аппарат защиты'**
  String get circuitProtection;

  /// No description provided for @circuitPhase.
  ///
  /// In ru, this message translates to:
  /// **'Фаза'**
  String get circuitPhase;

  /// No description provided for @circuitResetManual.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить ручные изменения'**
  String get circuitResetManual;

  /// No description provided for @protectionMcb.
  ///
  /// In ru, this message translates to:
  /// **'Автомат'**
  String get protectionMcb;

  /// No description provided for @protectionMcbRcd.
  ///
  /// In ru, this message translates to:
  /// **'Автомат + УЗО'**
  String get protectionMcbRcd;

  /// No description provided for @protectionRcbo.
  ///
  /// In ru, this message translates to:
  /// **'Дифавтомат'**
  String get protectionRcbo;

  /// No description provided for @protectionGroup.
  ///
  /// In ru, this message translates to:
  /// **'Автомат под общим УЗО'**
  String get protectionGroup;

  /// No description provided for @circuitDevices.
  ///
  /// In ru, this message translates to:
  /// **'Приборы'**
  String get circuitDevices;

  /// No description provided for @estimateScenario.
  ///
  /// In ru, this message translates to:
  /// **'Сценарий'**
  String get estimateScenario;

  /// No description provided for @scenarioEconomy.
  ///
  /// In ru, this message translates to:
  /// **'Эконом'**
  String get scenarioEconomy;

  /// No description provided for @scenarioStandard.
  ///
  /// In ru, this message translates to:
  /// **'Стандарт'**
  String get scenarioStandard;

  /// No description provided for @scenarioPremium.
  ///
  /// In ru, this message translates to:
  /// **'Премиум'**
  String get scenarioPremium;

  /// No description provided for @estimateTotal.
  ///
  /// In ru, this message translates to:
  /// **'Итого'**
  String get estimateTotal;

  /// No description provided for @estimateTypical.
  ///
  /// In ru, this message translates to:
  /// **'Типично {price}'**
  String estimateTypical(String price);

  /// No description provided for @estimateApparatus.
  ///
  /// In ru, this message translates to:
  /// **'Аппараты защиты'**
  String get estimateApparatus;

  /// No description provided for @estimateAuxiliary.
  ///
  /// In ru, this message translates to:
  /// **'Вспомогательные устройства'**
  String get estimateAuxiliary;

  /// No description provided for @estimateCable.
  ///
  /// In ru, this message translates to:
  /// **'Кабель'**
  String get estimateCable;

  /// No description provided for @estimateModules.
  ///
  /// In ru, this message translates to:
  /// **'Модулей DIN: {count}'**
  String estimateModules(int count);

  /// No description provided for @estimateOptions.
  ///
  /// In ru, this message translates to:
  /// **'Состав'**
  String get estimateOptions;

  /// No description provided for @estimateVoltageRelay.
  ///
  /// In ru, this message translates to:
  /// **'Реле напряжения'**
  String get estimateVoltageRelay;

  /// No description provided for @estimateSpd.
  ///
  /// In ru, this message translates to:
  /// **'УЗИП'**
  String get estimateSpd;

  /// No description provided for @estimateOverhead.
  ///
  /// In ru, this message translates to:
  /// **'Воздушный ввод (УЗИП тип 1+2)'**
  String get estimateOverhead;

  /// No description provided for @estimateCableMark.
  ///
  /// In ru, this message translates to:
  /// **'Марка медного кабеля'**
  String get estimateCableMark;

  /// No description provided for @estimateWarnings.
  ///
  /// In ru, this message translates to:
  /// **'Предупреждения'**
  String get estimateWarnings;

  /// No description provided for @estimateNotIncluded.
  ///
  /// In ru, this message translates to:
  /// **'Не включено'**
  String get estimateNotIncluded;

  /// No description provided for @estimatePickModel.
  ///
  /// In ru, this message translates to:
  /// **'Выбор модели'**
  String get estimatePickModel;

  /// No description provided for @estimateRequirement.
  ///
  /// In ru, this message translates to:
  /// **'Требование: {requirement}'**
  String estimateRequirement(String requirement);

  /// No description provided for @estimateCustomPrice.
  ///
  /// In ru, this message translates to:
  /// **'Своя цена, ₽'**
  String get estimateCustomPrice;

  /// No description provided for @estimateResetSelection.
  ///
  /// In ru, this message translates to:
  /// **'Подбирать автоматически'**
  String get estimateResetSelection;

  /// No description provided for @compatibilityExact.
  ///
  /// In ru, this message translates to:
  /// **'точное соответствие'**
  String get compatibilityExact;

  /// No description provided for @compatibilityDifferences.
  ///
  /// In ru, this message translates to:
  /// **'подходит, есть отличия'**
  String get compatibilityDifferences;

  /// No description provided for @estimateNoModels.
  ///
  /// In ru, this message translates to:
  /// **'В каталоге нет подходящих моделей'**
  String get estimateNoModels;

  /// No description provided for @tabBoard.
  ///
  /// In ru, this message translates to:
  /// **'Щит'**
  String get tabBoard;

  /// No description provided for @stepBack.
  ///
  /// In ru, this message translates to:
  /// **'Назад'**
  String get stepBack;

  /// No description provided for @stepRoomsSummary.
  ///
  /// In ru, this message translates to:
  /// **'{rooms} пом. · {devices} приб.'**
  String stepRoomsSummary(int rooms, int devices);

  /// No description provided for @stepCircuitsSummary.
  ///
  /// In ru, this message translates to:
  /// **'{circuits} лин. · {failed} ✕'**
  String stepCircuitsSummary(int circuits, int failed);

  /// No description provided for @stepNeedRooms.
  ///
  /// In ru, this message translates to:
  /// **'Добавьте хотя бы одно помещение'**
  String get stepNeedRooms;

  /// No description provided for @stepFailedCircuits.
  ///
  /// In ru, this message translates to:
  /// **'Не проходят: {numbers}'**
  String stepFailedCircuits(String numbers);

  /// No description provided for @circuitsViewBoard.
  ///
  /// In ru, this message translates to:
  /// **'Щит'**
  String get circuitsViewBoard;

  /// No description provided for @circuitsViewList.
  ///
  /// In ru, this message translates to:
  /// **'Список'**
  String get circuitsViewList;

  /// No description provided for @boardEnclosure.
  ///
  /// In ru, this message translates to:
  /// **'Корпус {rails}×{perRail} = {total} мод. · занято {occupied} · резерв {reserve}'**
  String boardEnclosure(int rails, int perRail, int total, int occupied, int reserve);

  /// No description provided for @boardRail.
  ///
  /// In ru, this message translates to:
  /// **'Рейка {number} · {used}/{capacity}'**
  String boardRail(int number, int used, int capacity);

  /// No description provided for @boardReserveNote.
  ///
  /// In ru, this message translates to:
  /// **'Резерв не менее {percent} % — допущение, требует проверки. Цвет полосы — фаза, рамка — статус линии.'**
  String boardReserveNote(int percent);

  /// No description provided for @boardIncomer.
  ///
  /// In ru, this message translates to:
  /// **'Ввод'**
  String get boardIncomer;

  /// No description provided for @boardRcd.
  ///
  /// In ru, this message translates to:
  /// **'УЗО'**
  String get boardRcd;

  /// No description provided for @boardAuxiliary.
  ///
  /// In ru, this message translates to:
  /// **'Доп.'**
  String get boardAuxiliary;

  /// No description provided for @projectsEmptyHint.
  ///
  /// In ru, this message translates to:
  /// **'Создайте проект — линии, щит и смета посчитаются по нормам автоматически.'**
  String get projectsEmptyHint;

  /// No description provided for @projectsImportPickAnother.
  ///
  /// In ru, this message translates to:
  /// **'Выбрать другой файл'**
  String get projectsImportPickAnother;

  /// No description provided for @copyErrorDetails.
  ///
  /// In ru, this message translates to:
  /// **'Скопировать подробности'**
  String get copyErrorDetails;

  /// No description provided for @projectDeleteConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить проект'**
  String get projectDeleteConfirm;

  /// No description provided for @roomDeleteConfirm.
  ///
  /// In ru, this message translates to:
  /// **'Удалить помещение'**
  String get roomDeleteConfirm;

  /// No description provided for @roomsEmptyTitle.
  ///
  /// In ru, this message translates to:
  /// **'Помещений пока нет'**
  String get roomsEmptyTitle;

  /// No description provided for @deviceDelete.
  ///
  /// In ru, this message translates to:
  /// **'Удалить прибор'**
  String get deviceDelete;

  /// No description provided for @deviceDeleteTitle.
  ///
  /// In ru, this message translates to:
  /// **'Удалить прибор «{name}»?'**
  String deviceDeleteTitle(String name);

  /// No description provided for @deviceDeleteMessage.
  ///
  /// In ru, this message translates to:
  /// **'Прибор будет убран из помещения, линии и смета пересчитаются.'**
  String get deviceDeleteMessage;

  /// No description provided for @devicesNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Ничего не найдено по запросу «{query}»'**
  String devicesNotFound(String query);

  /// No description provided for @devicesSearchReset.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить поиск'**
  String get devicesSearchReset;

  /// No description provided for @circuitsEmptyAction.
  ///
  /// In ru, this message translates to:
  /// **'Добавить помещения'**
  String get circuitsEmptyAction;

  /// No description provided for @fieldRequired.
  ///
  /// In ru, this message translates to:
  /// **'Заполните поле'**
  String get fieldRequired;

  /// No description provided for @fieldNumber.
  ///
  /// In ru, this message translates to:
  /// **'Введите число, например 2,5'**
  String get fieldNumber;

  /// No description provided for @fieldMin.
  ///
  /// In ru, this message translates to:
  /// **'Укажите значение не меньше {min}'**
  String fieldMin(String min);

  /// No description provided for @fieldAbove.
  ///
  /// In ru, this message translates to:
  /// **'Укажите значение больше {min}'**
  String fieldAbove(String min);

  /// No description provided for @fieldRange.
  ///
  /// In ru, this message translates to:
  /// **'Укажите значение от {min} до {max}'**
  String fieldRange(String min, String max);

  /// No description provided for @projectsAll.
  ///
  /// In ru, this message translates to:
  /// **'Все проекты'**
  String get projectsAll;

  /// No description provided for @columnNumber.
  ///
  /// In ru, this message translates to:
  /// **'№'**
  String get columnNumber;

  /// No description provided for @columnCircuit.
  ///
  /// In ru, this message translates to:
  /// **'Линия'**
  String get columnCircuit;

  /// No description provided for @columnProtection.
  ///
  /// In ru, this message translates to:
  /// **'Защита'**
  String get columnProtection;

  /// No description provided for @columnCable.
  ///
  /// In ru, this message translates to:
  /// **'Кабель, мм²'**
  String get columnCable;

  /// No description provided for @columnLength.
  ///
  /// In ru, this message translates to:
  /// **'Длина, м'**
  String get columnLength;

  /// No description provided for @columnCurrent.
  ///
  /// In ru, this message translates to:
  /// **'Ток, А'**
  String get columnCurrent;

  /// No description provided for @columnPhase.
  ///
  /// In ru, this message translates to:
  /// **'Фаза'**
  String get columnPhase;

  /// No description provided for @settingsOpen.
  ///
  /// In ru, this message translates to:
  /// **'Открыть настройки'**
  String get settingsOpen;

  /// No description provided for @stepGoRooms.
  ///
  /// In ru, this message translates to:
  /// **'Перейти к помещениям'**
  String get stepGoRooms;

  /// No description provided for @stepGoCircuits.
  ///
  /// In ru, this message translates to:
  /// **'Перейти к линиям'**
  String get stepGoCircuits;

  /// No description provided for @stepGoEstimate.
  ///
  /// In ru, this message translates to:
  /// **'Перейти к смете'**
  String get stepGoEstimate;

  /// No description provided for @projectNotFoundHint.
  ///
  /// In ru, this message translates to:
  /// **'Возможно, его удалили. Откройте список и выберите другой проект.'**
  String get projectNotFoundHint;

  /// No description provided for @projectsSearch.
  ///
  /// In ru, this message translates to:
  /// **'Поиск проекта'**
  String get projectsSearch;

  /// No description provided for @projectsNotFound.
  ///
  /// In ru, this message translates to:
  /// **'Нет проектов по запросу «{query}»'**
  String projectsNotFound(String query);

  /// No description provided for @projectsSearchReset.
  ///
  /// In ru, this message translates to:
  /// **'Сбросить поиск'**
  String get projectsSearchReset;

  /// No description provided for @projectsSorted.
  ///
  /// In ru, this message translates to:
  /// **'Сначала недавно изменённые'**
  String get projectsSorted;
}

class _CommonTranslationsLocalizationsDelegate
    extends LocalizationsDelegate<CommonTranslationsLocalizations> {
  const _CommonTranslationsLocalizationsDelegate();

  @override
  Future<CommonTranslationsLocalizations> load(Locale locale) {
    return SynchronousFuture<CommonTranslationsLocalizations>(
      lookupCommonTranslationsLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) => <String>['ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_CommonTranslationsLocalizationsDelegate old) => false;
}

CommonTranslationsLocalizations lookupCommonTranslationsLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ru':
      return CommonTranslationsLocalizationsRu();
  }

  throw FlutterError(
    'CommonTranslationsLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
