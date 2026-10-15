import 'dart:typed_data';

import 'package:electrical_core/electrical_core.dart';
import 'package:estimate_core/estimate_core.dart';
import 'package:meta/meta.dart';
import 'package:norms_data/norms_data.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Fonts with Cyrillic and Greek glyphs (TrueType bytes), e.g. Noto Sans.
@immutable
final class const ReportFonts({
  /// Regular face.
  required final ByteData regular,

  /// Bold face.
  required final ByteData bold,
});

/// Data shown in the report.
@immutable
final class const ProjectReportData({
  /// Project name.
  required final String projectName,

  /// Generation time (local time is shown).
  required final DateTime generatedAt,

  /// App version for the footer.
  required final String appVersion,

  /// Calculation input.
  required final ProjectInput input,

  /// Calculation result.
  required final ProjectResult result,

  /// Estimate; `null` — the estimate sections are omitted.
  final EstimateResult? estimate,

  /// Switchboard; `null` — the switchboard section is omitted.
  final SwitchboardLayout? board,
});

/// Disclaimer printed on the first page.
const reportDisclaimer =
    'Ориентировочный расчёт. Не является проектной документацией и не заменяет проект, '
    'выполненный квалифицированным специалистом. Перед монтажом параметры сети (сопротивление '
    'петли «фаза — нуль», ток КЗ) должны быть измерены, а решения — проверены.';

/// Builds the A4 PDF report.
///
/// Sections: title, initial data, input load, circuits, notes on checks, phase balance,
/// specification and estimate, switchboard, assumptions and exclusions.
Future<Uint8List> buildProjectReport(ProjectReportData data, ReportFonts fonts) {
  final document = pw.Document(
    title: data.projectName,
    author: 'Щитовик',
    creator: 'Щитовик ${data.appVersion}',
    theme: pw.ThemeData.withFont(base: pw.Font.ttf(fonts.regular), bold: pw.Font.ttf(fonts.bold)),
  );
  document.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4.landscape,
      margin: const pw.EdgeInsets.fromLTRB(28, 28, 28, 32),
      footer: (context) => _footer(context, data),
      build: (context) => [
        ..._title(data),
        ..._initialData(data),
        ..._incomer(data),
        ..._circuits(data),
        ..._notes(data),
        ..._phaseBalance(data),
        if (data.estimate != null) ..._estimate(data.estimate!),
        if (data.board != null) ..._switchboard(data, data.board!),
        ..._assumptions(data),
      ],
    ),
  );
  return document.save();
}

// ------------------------------------------------------------------ helpers

const _small = 8.0;
const _body = 9.5;
const _grey = PdfColor.fromInt(0xFF666666);
const _headerFill = PdfColor.fromInt(0xFFE8EEF5);

String _num(double? v, [int digits = 1]) {
  if (v == null) return '—';
  String s = v.toStringAsFixed(digits);
  if (s.contains('.')) s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  return s.replaceAll('.', ',');
}

String _rub(int kopecks) {
  final rubles = (kopecks / 100).round().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < rubles.length; i++) {
    if (i > 0 && (rubles.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(rubles[i]);
  }
  return '$buffer ₽';
}

String _range(PriceRange p) =>
    '${_rub(p.minKopecks)} … ${_rub(p.maxKopecks)} (типично ${_rub(p.typicalKopecks)})';

String _date(DateTime t) {
  final DateTime local = t.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.day)}.${two(local.month)}.${local.year} ${two(local.hour)}:${two(local.minute)}';
}

pw.Widget _heading(String text) => pw.Padding(
  padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
  child: pw.Text(text, style: const pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
);

/// Replaces math symbols missing from the report font.
String _printable(String text) =>
    text.replaceAll('≤', '<=').replaceAll('≥', '>=').replaceAll('≈', '~');

pw.Widget _paragraph(String text, {double size = _body, PdfColor? color}) => pw.Padding(
  padding: const pw.EdgeInsets.only(bottom: 3),
  child: pw.Text(
    _printable(text),
    style: pw.TextStyle(fontSize: size, color: color),
  ),
);

pw.Widget _table(
  List<String> headers,
  List<List<String>> rows, {
  Map<int, pw.TableColumnWidth>? widths,
}) => pw.TableHelper.fromTextArray(
  headers: headers,
  data: [
    for (final row in rows) [for (final cell in row) _printable(cell)],
  ],
  columnWidths: widths,
  headerStyle: const pw.TextStyle(fontSize: _small, fontWeight: pw.FontWeight.bold),
  headerDecoration: const pw.BoxDecoration(color: _headerFill),
  cellStyle: const pw.TextStyle(fontSize: _small),
  cellAlignment: pw.Alignment.centerLeft,
  headerAlignment: pw.Alignment.centerLeft,
  cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 2),
  border: pw.TableBorder.all(color: const PdfColor.fromInt(0xFFBBBBBB), width: 0.5),
);

pw.Widget _footer(pw.Context context, ProjectReportData data) => pw.Row(
  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
  children: [
    pw.Text(
      'Щитовик ${data.appVersion} · алгоритм ${data.result.algorithmVersion} · ${data.projectName}',
      style: const pw.TextStyle(fontSize: 7, color: _grey),
    ),
    pw.Text(
      'Стр. ${context.pageNumber} из ${context.pagesCount}',
      style: const pw.TextStyle(fontSize: 7, color: _grey),
    ),
  ],
);

// ------------------------------------------------------------------ sections

List<pw.Widget> _title(ProjectReportData data) {
  final ProjectInput input = data.input;
  final ProjectResult result = data.result;
  return [
    pw.Text(
      'Расчёт электрощита',
      style: const pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 4),
    pw.Text(data.projectName, style: const pw.TextStyle(fontSize: 14)),
    pw.SizedBox(height: 6),
    _paragraph(
      '${input.objectType.label}, ввод ${input.supplyPhases.label}, '
      '${_num(result.phaseVoltageV, 0)}/${_num(result.lineVoltageV, 0)} В. '
      'Сформировано ${_date(data.generatedAt)}. Итоговый статус: ${result.status.label}.',
    ),
    pw.Container(
      margin: const pw.EdgeInsets.only(top: 6),
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: const PdfColor.fromInt(0xFFCC8800)),
      ),
      child: pw.Text(reportDisclaimer, style: const pw.TextStyle(fontSize: _small)),
    ),
  ];
}

List<pw.Widget> _initialData(ProjectReportData data) {
  final rows = <List<String>>[];
  for (final RoomInput room in data.input.rooms) {
    for (final DeviceInput d in data.input.devices.where((d) => d.roomId == room.id)) {
      rows.add([
        room.name,
        d.name,
        d.quantity.toString(),
        _num(d.powerW / 1000, 2),
        _num(d.totalPowerW / 1000, 2),
        if (d.phases == 3) '3ф' else '1ф',
        _num(d.cosPhi, 2),
        _num(d.usageFactor, 2),
        if (d.connection == DeviceConnection.socket) 'розетка' else 'стационарно',
      ]);
    }
  }
  final CableDefaults defaults = data.input.cableDefaults;
  return [
    _heading('1. Исходные данные'),
    _paragraph(
      'Кабель по умолчанию: ${defaults.material.label}, изоляция ${defaults.insulation == Insulation.pvc ? 'ПВХ' : 'СПЭ'}, '
      'температура среды ${_num(defaults.ambientTemperatureC, 0)} °C, совместно проложенных цепей ${defaults.groupedCircuits}, '
      'длина линий ${defaults.lengthM == null ? 'не задана' : '${_num(defaults.lengthM)} м'}.',
    ),
    _table(
      ['Помещение', 'Приёмник', 'Кол.', 'P, кВт', 'ΣP, кВт', 'Фазы', 'cos φ', 'ku', 'Подключение'],
      rows,
    ),
  ];
}

List<pw.Widget> _incomer(ProjectReportData data) {
  final IncomerResult incomer = data.result.incomer;
  final SharedRcdResult? fire = data.result.fireRcd;
  final List<List<String>> rows = [
    ['Установленная мощность', '${_num(incomer.installedPowerW / 1000, 2)} кВт'],
    ['Нагрузка «по приборам» (Σ P·ku)', '${_num(incomer.demandByDevicesW / 1000, 2)} кВт'],
    ['Расчётная нагрузка по СП 256', '${_num(incomer.demandNormativeW / 1000, 2)} кВт'],
    ['Метод', incomer.normativeMethod],
    ['cos φ ввода', _num(incomer.cosPhi, 2)],
    ['Расчётный ток (наиболее нагруженная фаза)', '${_num(incomer.designCurrentA)} А'],
    [
      'Вводной автомат',
      if (incomer.breakerA == null)
        'вне модульного ряда'
      else
        '${_num(incomer.breakerA, 0)} А${incomer.breakerSource == ValueSource.manual ? ' (существующий)' : ''}',
    ],
    if (data.input.supply.allowedPowerKw != null)
      ['Разрешённая мощность', '${_num(data.input.supply.allowedPowerKw, 2)} кВт'],
    if (fire != null)
      [
        'УЗО на вводе',
        '${_num(fire.ratedA, 0)} А, ${_num(fire.residualMa, 0)} мА, тип ${fire.type} S',
      ],
    for (final c in incomer.checks) [c.message, c.status.label],
  ];
  final CableResult? cable = incomer.cable;
  return [
    _heading('2. Ввод'),
    _table(
      ['Параметр', 'Значение'],
      rows,
      widths: {0: const pw.FlexColumnWidth(2), 1: const pw.FlexColumnWidth(5)},
    ),
    if (cable != null)
      _paragraph(
        'Кабель ввода: ${cable.label} мм², ${cable.material.label}, ${_num(cable.lengthM)} м, ΔU ${_num(cable.voltageDropPercent, 2)} %.',
      ),
  ];
}

List<pw.Widget> _circuits(ProjectReportData data) {
  final List<List<String>> rows = [
    for (final c in data.result.circuits)
      [
        c.number.toString(),
        c.name,
        c.phase?.label ?? '3ф',
        _num(c.installedPowerW / 1000, 2),
        _num(c.designCurrentA),
        c.protection.description,
        '${c.cable.label} мм²',
        _num(c.cable.lengthM),
        _num(c.cable.ampacityA),
        _num(c.cable.voltageDropPercent, 2),
        _num(c.cable.faultCurrentMinA, 0),
        c.status.label,
      ],
  ];
  return [
    _heading('3. Групповые линии'),
    _table(
      [
        '№',
        'Линия',
        'Фаза',
        'P, кВт',
        'Iр, А',
        'Защита',
        'Кабель',
        'L, м',
        'Iz, А',
        'ΔU, %',
        'Iк мин, А',
        'Статус',
      ],
      rows,
      widths: {
        0: const pw.FixedColumnWidth(18),
        1: const pw.FlexColumnWidth(3),
        2: const pw.FixedColumnWidth(26),
        5: const pw.FlexColumnWidth(3),
        11: const pw.FlexColumnWidth(1.4),
      },
    ),
  ];
}

List<pw.Widget> _notes(ProjectReportData data) {
  final rows = <List<String>>[];
  for (final CircuitResult c in data.result.circuits) {
    for (final Check check in c.allChecks) {
      if (check.status == CheckStatus.failed || check.status == CheckStatus.warning) {
        rows.add(['№${c.number}', check.status.label, check.message, check.reference ?? '']);
      }
    }
    final RcdResult? rcd = c.protection.rcd;
    if (rcd != null) rows.add(['№${c.number}', 'УЗО', rcd.reasons.join('; '), '']);
  }
  final List<pw.Widget> issues = [
    for (final i in data.result.issues) _paragraph('• ${i.message}', size: _small),
  ];
  return [
    _heading('4. Замечания по проверкам и требования к УЗО'),
    if (rows.isEmpty) _paragraph('Замечаний нет.'),
    if (rows.isNotEmpty)
      _table(
        ['Линия', 'Статус', 'Пояснение', 'Норма'],
        rows,
        widths: {
          0: const pw.FixedColumnWidth(36),
          1: const pw.FixedColumnWidth(64),
          2: const pw.FlexColumnWidth(5),
          3: const pw.FlexColumnWidth(2),
        },
      ),
    ...issues,
  ];
}

List<pw.Widget> _phaseBalance(ProjectReportData data) {
  final PhaseBalanceResult? balance = data.result.phaseBalance;
  if (balance == null) return const [];
  return [
    _heading('5. Распределение по фазам'),
    _table(
      ['Фаза', 'Ожидаемый ток, А'],
      [
        for (final e in balance.loadsA.entries) [e.key.label, _num(e.value)],
      ],
    ),
    _paragraph(
      'Разница токов наиболее и наименее нагруженных фаз: ${_num(balance.imbalancePercent, 0)} % '
      '(рекомендуется не более ${_num(balance.limitPercent, 0)} %, СП 256 п. 10.5).',
    ),
  ];
}

List<pw.Widget> _estimate(EstimateResult estimate) {
  final apparatus = <String, ({int count, int modules})>{};
  for (final EstimateLine l in estimate.lines.where((l) => l.category != EstimateCategory.cable)) {
    final ({int count, int modules})? current = apparatus[l.description];
    apparatus[l.description] = (
      count: (current?.count ?? 0) + 1,
      modules: (current?.modules ?? 0) + l.moduleUnits,
    );
  }
  final cables = <String, double>{};
  for (final EstimateLine l in estimate.lines.where(
    (l) => l.category == EstimateCategory.cable && l.missing.isEmpty,
  )) {
    cables[l.description] = (cables[l.description] ?? 0) + l.quantity;
  }
  final List<List<String>> lines = [
    for (final l in estimate.lines)
      [
        l.title,
        l.description,
        '${_num(l.quantity)} ${l.unit}',
        if (l.missing.isEmpty) _rub(l.total.typicalKopecks) else 'нет: ${l.missing.join(', ')}',
      ],
  ];
  return [
    _heading('6. Спецификация'),
    _table(
      ['Аппарат', 'Кол.', 'Модулей'],
      [
        for (final e in apparatus.entries)
          [e.key, e.value.count.toString(), e.value.modules.toString()],
      ],
      widths: {0: const pw.FlexColumnWidth(6)},
    ),
    if (cables.isNotEmpty) pw.SizedBox(height: 6),
    if (cables.isNotEmpty)
      _table(
        ['Кабель', 'Длина с запасом, м'],
        [
          for (final e in cables.entries) [e.key, _num(e.value)],
        ],
      ),
    _paragraph('Всего модулей DIN: ${estimate.moduleUnits}.'),
    _heading('7. Смета (ориентировочно)'),
    _table(
      ['Позиция', 'Что', 'Кол.', 'Типично'],
      lines,
      widths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(4),
      },
    ),
    pw.SizedBox(height: 6),
    _paragraph('Аппараты защиты: ${_range(estimate.apparatusTotal)}'),
    _paragraph('Вспомогательные устройства: ${_range(estimate.auxiliaryTotal)}'),
    _paragraph('Кабель: ${_range(estimate.cableTotal)}'),
    pw.Text(
      'Итого: ${_range(estimate.total)}',
      style: const pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
    ),
    pw.SizedBox(height: 4),
    for (final w in estimate.warnings) _paragraph('• ${w.message}', size: _small),
    _paragraph('Не включено: ${estimate.notIncluded.join('; ')}.', size: _small),
  ];
}

/// Page width between the margins of A4 landscape.
const double _contentWidth = 841.89 - 56;

/// Conductor colours of the phases by ГОСТ 33542-2015 (IEC 60445): L1 brown, L2 black, L3 grey.
PdfColor _phaseColor(Phase? phase) => switch (phase) {
  Phase.l1 => const PdfColor.fromInt(0xFF795548),
  Phase.l2 => const PdfColor.fromInt(0xFF212121),
  Phase.l3 => const PdfColor.fromInt(0xFF9E9E9E),
  null => const PdfColor.fromInt(0xFF2B5C8A),
};

List<pw.Widget> _switchboard(ProjectReportData data, SwitchboardLayout board) {
  final int perRail = board.rails.fold(board.modulesPerRail, (m, r) => r.used > m ? r.used : m);
  final double module = (_contentWidth / perRail).clamp(0.0, 32.0);
  return [
    pw.NewPage(),
    _heading('8. Щит'),
    _paragraph(
      'Корпус ${board.enclosureRails}×${board.modulesPerRail} = '
      '${board.enclosureRails * board.modulesPerRail} мод., занято ${board.occupiedModules}. '
      'Ширина аппаратов — по моделям сметы; резерв не менее '
      '${_num(enclosureReserveShare * 100, 0)} % — допущение. Полоса — фаза (L1 коричневая, '
      'L2 чёрная, L3 серая).',
    ),
    for (var r = 0; r < board.rails.length; r++)
      pw.Padding(
        padding: const pw.EdgeInsets.only(top: 6),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Рейка ${r + 1} · ${board.rails[r].used}/${board.rails[r].capacity}'
              '${r >= board.enclosureRails ? ' · не помещается в корпус' : ''}',
              style: const pw.TextStyle(fontSize: _small, color: _grey),
            ),
            pw.SizedBox(height: 2),
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                for (final item in board.rails[r].items) _boardModule(data, item, module),
                for (var i = board.rails[r].used; i < board.rails[r].capacity; i++)
                  pw.Container(
                    width: module,
                    height: 64,
                    decoration: pw.BoxDecoration(
                      border: pw.Border.all(color: _grey, width: 0.5, style: pw.BorderStyle.dashed),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    pw.SizedBox(height: 4),
    for (final w in board.warnings) _paragraph('• ${_boardWarning(data, w)}', size: _small),
  ];
}

pw.Widget _boardModule(ProjectReportData data, BoardItem item, double module) {
  final ProjectResult result = data.result;
  final (String top, String title, String bottom, PdfColor strip) = switch (item.kind) {
    BoardItemKind.incomer => (
      'Ввод',
      'C${_num(result.incomer.breakerA, 0)}',
      '${_num(result.incomer.designCurrentA)} А',
      const PdfColor.fromInt(0xFF2B5C8A),
    ),
    BoardItemKind.fireRcd => (
      'УЗО',
      '${_num(result.fireRcd!.residualMa, 0)} мА',
      '${_num(result.fireRcd!.ratedA, 0)} А',
      const PdfColor.fromInt(0xFFB3261E),
    ),
    BoardItemKind.auxiliary => () {
      final EstimateLine? line = data.estimate?.lines.where((l) => l.id == item.id).firstOrNull;
      return ('Доп.', line?.title ?? '', line?.description ?? '', _grey);
    }(),
    BoardItemKind.groupRcd => () {
      final SharedRcdResult rcd = result.sharedRcds.firstWhere((x) => x.id == item.id);
      return (
        'УЗО',
        '${_num(rcd.residualMa, 0)} мА',
        '${_num(rcd.ratedA, 0)} А',
        const PdfColor.fromInt(0xFF2B5C8A),
      );
    }(),
    BoardItemKind.circuit => () {
      final CircuitResult c = result.circuits.firstWhere((x) => x.id == item.id);
      return (
        '${c.number} · ${c.phase?.label ?? '3ф'}',
        c.protection.label,
        c.name,
        _phaseColor(c.phase),
      );
    }(),
  };
  return pw.Container(
    width: item.units * module,
    height: 64,
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: const PdfColor.fromInt(0xFF444444), width: 0.6),
      color: PdfColors.white,
    ),
    child: pw.Column(
      children: [
        pw.Container(
          height: 10,
          color: strip,
          alignment: pw.Alignment.center,
          child: pw.Text(
            _printable(top),
            maxLines: 1,
            style: pw.TextStyle(
              fontSize: 6,
              color: strip.luminance < 0.4 ? PdfColors.white : PdfColors.black,
            ),
          ),
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          _printable(title),
          maxLines: 1,
          style: const pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold),
        ),
        pw.Spacer(),
        pw.Padding(
          padding: const pw.EdgeInsets.fromLTRB(1, 0, 1, 2),
          child: pw.Text(
            _printable(bottom),
            maxLines: 3,
            textAlign: pw.TextAlign.center,
            style: const pw.TextStyle(fontSize: 5.5),
          ),
        ),
      ],
    ),
  );
}

String _boardWarning(ProjectReportData data, BoardWarning warning) => switch (warning) {
  BoardRailOverfull(:final rail) => 'Рейка ${rail + 1} переполнена: аппараты шире рейки.',
  BoardEnclosureTooSmall() => 'Аппараты не помещаются в выбранный корпус.',
  BoardReserveLow() =>
    'Резерв меньше ${_num(enclosureReserveShare * 100, 0)} % — нет места для новых линий.',
  BoardGroupSplit(:final rcdId) => () {
    final List<String> numbers = [
      for (final c in data.result.circuits)
        if (data.result.sharedRcds.any((r) => r.id == rcdId && r.circuitIds.contains(c.id)))
          '№${c.number}',
    ];
    return 'Группа УЗО (линии ${numbers.join(', ')}) разнесена: аппараты не стоят подряд '
        'на одной рейке, гребёнкой их не соединить — нужны перемычки.';
  }(),
};

List<pw.Widget> _assumptions(ProjectReportData data) => [
  _heading('Допущения расчёта'),
  for (final a in data.result.assumptions) _paragraph('• ${a.message}', size: _small),
  _paragraph(
    '• Короткое замыкание: минимальный ток Iк = 0,95·U0 / Zs, проводники при максимальной рабочей '
    'температуре; термическая стойкость кабеля при КЗ не оценивалась.',
    size: _small,
  ),
  _paragraph(
    'Нормативная база: ГОСТ Р 50571.5.52-2011, ГОСТ Р 50571.4.41-2022, ГОСТ Р 50571.4.43, '
    'ГОСТ Р 50571.5.54, СП 256.1325800.2016, ПУЭ (7-е изд.). Версии наборов данных: '
    '${data.result.datasetVersions.values.toSet().join(', ')}.',
    size: _small,
    color: _grey,
  ),
];
