// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'common_translations_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class CommonTranslationsLocalizationsRu extends CommonTranslationsLocalizations {
  CommonTranslationsLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Щитовик';

  @override
  String get ok => 'ОК';

  @override
  String get cancel => 'Отмена';

  @override
  String get confirm => 'Подтвердить';

  @override
  String get retry => 'Повторить';

  @override
  String get moreActions => 'Ещё';

  @override
  String get initializationFailed => 'Не удалось запустить приложение';

  @override
  String get projectsTitle => 'Проекты';

  @override
  String get projectsEmpty => 'Проектов пока нет';

  @override
  String get settingsTitle => 'Настройки';

  @override
  String get themeModeTitle => 'Тема';

  @override
  String get themeModeSystem => 'Как в системе';

  @override
  String get themeModeLight => 'Светлая';

  @override
  String get themeModeDark => 'Тёмная';

  @override
  String get estimateDisclaimer =>
      'Ориентировочный расчёт. Не заменяет проект, выполненный квалифицированным специалистом.';

  @override
  String get delete => 'Удалить';

  @override
  String get save => 'Сохранить';

  @override
  String get close => 'Закрыть';

  @override
  String get auto => 'Авто';

  @override
  String get yes => 'Да';

  @override
  String get no => 'Нет';

  @override
  String get reset => 'Сбросить';

  @override
  String get notSet => 'не задано';

  @override
  String get projectsCreate => 'Создать проект';

  @override
  String get projectsImport => 'Импортировать проект';

  @override
  String projectsImportFailed(String message) {
    return 'Не удалось импортировать проект: $message';
  }

  @override
  String projectsImported(String name) {
    return 'Проект «$name» импортирован';
  }

  @override
  String get projectsDemoTitle => 'Или начните с примера';

  @override
  String get projectsDemoOneRoom => '1-комнатная квартира';

  @override
  String get projectsDemoThreeRoom => '3-комнатная квартира';

  @override
  String get projectsDemoHouse => 'Частный дом';

  @override
  String projectsUpdated(String date) {
    return 'изменён $date';
  }

  @override
  String get projectDuplicate => 'Дублировать';

  @override
  String get projectExport => 'Экспортировать проект';

  @override
  String projectDeleteTitle(String name) {
    return 'Удалить проект «$name»?';
  }

  @override
  String get projectDeleteMessage =>
      'Проект, его помещения, линии и смета будут удалены без возможности восстановления.';

  @override
  String get projectNotFound => 'Проект не найден';

  @override
  String get createProjectTitle => 'Новый проект';

  @override
  String get createProjectName => 'Название';

  @override
  String get createProjectDefaultName => 'Мой проект';

  @override
  String get objectTypeTitle => 'Тип объекта';

  @override
  String get supplyTitle => 'Ввод';

  @override
  String get supplySingle => '1 фаза';

  @override
  String get supplyThree => '3 фазы';

  @override
  String get create => 'Создать';

  @override
  String get tabSetup => 'Объект';

  @override
  String get tabRooms => 'Помещения';

  @override
  String get tabCircuits => 'Линии';

  @override
  String get tabEstimate => 'Смета';

  @override
  String get reportPdf => 'Сохранить PDF';

  @override
  String get reportInProgress => 'Формируем PDF…';

  @override
  String get reportFailed =>
      'Не удалось сформировать отчёт. Повторите попытку; если ошибка повторится, скопируйте подробности для поддержки.';

  @override
  String get interfaceModeTitle => 'Режим';

  @override
  String get interfaceModeSimple => 'Простой';

  @override
  String get interfaceModeExpert => 'Экспертный';

  @override
  String get interfaceModeHint =>
      'В экспертном режиме доступны все параметры расчёта и ручная правка линий.';

  @override
  String get setupGeneral => 'Общее';

  @override
  String get setupSupply => 'Ввод и сеть';

  @override
  String get setupCable => 'Кабель по умолчанию';

  @override
  String get setupProtection => 'Защита';

  @override
  String get setupName => 'Название проекта';

  @override
  String get setupNote => 'Заметка';

  @override
  String get setupVoltage => 'Номинальное напряжение';

  @override
  String get setupAllowedPower => 'Разрешённая мощность, кВт';

  @override
  String get setupAllowedPowerHint => 'Из технических условий на присоединение';

  @override
  String get setupIncomerBreaker => 'Существующий вводной автомат, А';

  @override
  String get setupExternalLoop => 'Сопротивление петли «фаза — нуль» до щита, Ом';

  @override
  String get setupExternalLoopHint =>
      'По замеру или от сетевой организации; без него проверка КЗ — с допущением';

  @override
  String get setupCookingFuel => 'Плита';

  @override
  String get cookingFuelNaturalGas => 'Газовая';

  @override
  String get cookingFuelLiquefied => 'Сжиженный газ / твёрдое топливо';

  @override
  String get cookingFuelElectric => 'Электрическая';

  @override
  String get setupCommercialProfile => 'Профиль помещения';

  @override
  String get profileOffice => 'Офис';

  @override
  String get profileShop => 'Магазин';

  @override
  String get profileCatering => 'Общепит';

  @override
  String get profileServices => 'Салон, мастерская услуг';

  @override
  String get profileWorkshop => 'Мастерская со станками';

  @override
  String get setupRcdStrategy => 'Устройства защитного отключения';

  @override
  String get rcdStrategyRcbo => 'Дифавтомат на каждую линию';

  @override
  String get rcdStrategyRcd => 'Автомат + УЗО на каждую линию';

  @override
  String get rcdStrategyGrouped => 'Общие УЗО на группы линий';

  @override
  String get setupFireRcd => 'Противопожарное УЗО на вводе';

  @override
  String get setupMaterial => 'Материал жил';

  @override
  String get materialCopper => 'Медь';

  @override
  String get materialAluminium => 'Алюминий';

  @override
  String get setupInsulation => 'Изоляция';

  @override
  String get insulationPvc => 'ПВХ (70 °C)';

  @override
  String get insulationXlpe => 'Сшитый полиэтилен (90 °C)';

  @override
  String get setupMethod => 'Способ прокладки';

  @override
  String get setupAmbient => 'Температура среды, °C';

  @override
  String get setupGrouped => 'Цепей, проложенных вместе';

  @override
  String get setupDefaultLength => 'Длина линии по умолчанию, м';

  @override
  String get roomsEmpty => 'Добавьте помещения — приборы подставятся из типового набора';

  @override
  String get roomsAdd => 'Добавить помещение';

  @override
  String get roomsAddTitle => 'Добавить помещение';

  @override
  String get roomsEmptyRoom => 'Пустое помещение';

  @override
  String get roomRename => 'Переименовать';

  @override
  String get roomKind => 'Тип помещения';

  @override
  String get roomKindStandard => 'Жилое / обычное';

  @override
  String get roomKindKitchen => 'Кухня';

  @override
  String get roomKindBathroom => 'Ванная, душевая, сауна';

  @override
  String get roomKindOutdoor => 'Улица';

  @override
  String get roomKindGarage => 'Гараж, мастерская';

  @override
  String roomDeleteTitle(String name) {
    return 'Удалить помещение «$name»?';
  }

  @override
  String get roomDeleteMessage => 'Вместе с помещением будут удалены его приборы.';

  @override
  String get devicesAdd => 'Добавить прибор';

  @override
  String get devicesSearch => 'Поиск прибора';

  @override
  String get deviceCustom => 'Свой прибор';

  @override
  String get deviceName => 'Название';

  @override
  String get devicePower => 'Мощность одного, Вт';

  @override
  String get deviceQuantity => 'Количество';

  @override
  String get devicePhases => 'Фазы';

  @override
  String get deviceCosPhi => 'cos φ';

  @override
  String get deviceUsageFactor => 'Коэффициент использования ku';

  @override
  String get deviceInrush => 'Кратность пускового тока';

  @override
  String get deviceConnection => 'Подключение';

  @override
  String get connectionSocket => 'Через розетку';

  @override
  String get connectionFixed => 'Стационарно';

  @override
  String get deviceDedicated => 'Отдельная линия';

  @override
  String get dedicatedRequired => 'Обязательно';

  @override
  String get dedicatedRecommended => 'По умолчанию';

  @override
  String get dedicatedNo => 'Общая группа';

  @override
  String get circuitsEmpty => 'Линии появятся, когда вы добавите приборы';

  @override
  String get circuitsInput => 'Ввод';

  @override
  String get circuitsInstalled => 'Установленная мощность';

  @override
  String get circuitsByDevices => 'По приборам (Σ P·ku)';

  @override
  String get circuitsNormative => 'Расчётная по СП 256';

  @override
  String get circuitsDesignCurrent => 'Расчётный ток';

  @override
  String get circuitsIncomer => 'Вводной автомат';

  @override
  String get circuitsFireRcd => 'УЗО на вводе';

  @override
  String get circuitsPhases => 'Фазы';

  @override
  String get circuitsImbalance => 'Разница токов фаз';

  @override
  String get circuitsAssumptions => 'Допущения расчёта';

  @override
  String get circuitsIssues => 'Замечания';

  @override
  String get circuitStatus => 'Статус';

  @override
  String get circuitValues => 'Расчёт';

  @override
  String get circuitChecks => 'Проверки';

  @override
  String get circuitRcdReasons => 'Почему нужно УЗО';

  @override
  String get circuitSettings => 'Параметры линии';

  @override
  String get circuitExpert => 'Ручные изменения';

  @override
  String get circuitLength => 'Длина, м';

  @override
  String get circuitSection => 'Сечение, мм²';

  @override
  String get circuitBreaker => 'Номинал автомата, А';

  @override
  String get circuitCurve => 'Характеристика';

  @override
  String get circuitProtection => 'Аппарат защиты';

  @override
  String get circuitPhase => 'Фаза';

  @override
  String get circuitResetManual => 'Сбросить ручные изменения';

  @override
  String get protectionMcb => 'Автомат';

  @override
  String get protectionMcbRcd => 'Автомат + УЗО';

  @override
  String get protectionRcbo => 'Дифавтомат';

  @override
  String get protectionGroup => 'Автомат под общим УЗО';

  @override
  String get circuitDevices => 'Приборы';

  @override
  String get estimateScenario => 'Сценарий';

  @override
  String get scenarioEconomy => 'Эконом';

  @override
  String get scenarioStandard => 'Стандарт';

  @override
  String get scenarioPremium => 'Премиум';

  @override
  String get estimateTotal => 'Итого';

  @override
  String estimateTypical(String price) {
    return 'Типично $price';
  }

  @override
  String get estimateApparatus => 'Аппараты защиты';

  @override
  String get estimateAuxiliary => 'Вспомогательные устройства';

  @override
  String get estimateCable => 'Кабель';

  @override
  String estimateModules(int count) {
    return 'Модулей DIN: $count';
  }

  @override
  String get estimateOptions => 'Состав';

  @override
  String get estimateVoltageRelay => 'Реле напряжения';

  @override
  String get estimateSpd => 'УЗИП';

  @override
  String get estimateOverhead => 'Воздушный ввод (УЗИП тип 1+2)';

  @override
  String get estimateCableMark => 'Марка медного кабеля';

  @override
  String get estimateWarnings => 'Предупреждения';

  @override
  String get estimateNotIncluded => 'Не включено';

  @override
  String get estimatePickModel => 'Выбор модели';

  @override
  String estimateRequirement(String requirement) {
    return 'Требование: $requirement';
  }

  @override
  String get estimateCustomPrice => 'Своя цена, ₽';

  @override
  String get estimateResetSelection => 'Подбирать автоматически';

  @override
  String get compatibilityExact => 'точное соответствие';

  @override
  String get compatibilityDifferences => 'подходит, есть отличия';

  @override
  String get estimateNoModels => 'В каталоге нет подходящих моделей';

  @override
  String get tabBoard => 'Щит';

  @override
  String get stepBack => 'Назад';

  @override
  String stepRoomsSummary(int rooms, int devices) {
    return '$rooms пом. · $devices приб.';
  }

  @override
  String stepCircuitsSummary(int circuits, int failed) {
    return '$circuits лин. · $failed ✕';
  }

  @override
  String get stepNeedRooms => 'Добавьте хотя бы одно помещение';

  @override
  String stepFailedCircuits(String numbers) {
    return 'Не проходят: $numbers';
  }

  @override
  String get circuitsViewBoard => 'Щит';

  @override
  String get circuitsViewList => 'Список';

  @override
  String boardEnclosure(int rails, int perRail, int total, int occupied, int reserve) {
    return 'Корпус $rails×$perRail = $total мод. · занято $occupied · резерв $reserve';
  }

  @override
  String boardRail(int number, int used, int capacity) {
    return 'Рейка $number · $used/$capacity';
  }

  @override
  String boardReserveNote(int percent) {
    return 'Резерв не менее $percent % — допущение, требует проверки. Цвет полосы — фаза, рамка — статус линии.';
  }

  @override
  String get boardIncomer => 'Ввод';

  @override
  String get boardRcd => 'УЗО';

  @override
  String get boardAuxiliary => 'Доп.';

  @override
  String get projectsEmptyHint =>
      'Создайте проект — линии, щит и смета посчитаются по нормам автоматически.';

  @override
  String get projectsImportPickAnother => 'Выбрать другой файл';

  @override
  String get copyErrorDetails => 'Скопировать подробности';

  @override
  String get projectDeleteConfirm => 'Удалить проект';

  @override
  String get roomDeleteConfirm => 'Удалить помещение';

  @override
  String get roomsEmptyTitle => 'Помещений пока нет';

  @override
  String get deviceDelete => 'Удалить прибор';

  @override
  String deviceDeleteTitle(String name) {
    return 'Удалить прибор «$name»?';
  }

  @override
  String get deviceDeleteMessage => 'Прибор будет убран из помещения, линии и смета пересчитаются.';

  @override
  String devicesNotFound(String query) {
    return 'Ничего не найдено по запросу «$query»';
  }

  @override
  String get devicesSearchReset => 'Сбросить поиск';

  @override
  String get circuitsEmptyAction => 'Добавить помещения';

  @override
  String get fieldRequired => 'Заполните поле';

  @override
  String get fieldNumber => 'Введите число, например 2,5';

  @override
  String fieldMin(String min) {
    return 'Укажите значение не меньше $min';
  }

  @override
  String fieldAbove(String min) {
    return 'Укажите значение больше $min';
  }

  @override
  String fieldRange(String min, String max) {
    return 'Укажите значение от $min до $max';
  }
}
