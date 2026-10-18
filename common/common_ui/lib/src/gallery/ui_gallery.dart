import 'package:common_ui/src/tokens/ui_colors.dart';
import 'package:common_ui/src/tokens/ui_icons.dart';
import 'package:common_ui/src/tokens/ui_metrics.dart';
import 'package:common_ui/src/tokens/ui_text_styles.dart';
import 'package:common_ui/src/tokens/ui_theme.dart';
import 'package:common_ui/src/widgets/ui_button.dart';
import 'package:common_ui/src/widgets/ui_disclosure.dart';
import 'package:common_ui/src/widgets/ui_empty_state.dart';
import 'package:common_ui/src/widgets/ui_inputs.dart';
import 'package:common_ui/src/widgets/ui_metrics.dart';
import 'package:common_ui/src/widgets/ui_navigation.dart';
import 'package:common_ui/src/widgets/ui_overlays.dart';
import 'package:common_ui/src/widgets/ui_rows.dart';
import 'package:common_ui/src/widgets/ui_status.dart';
import 'package:common_ui/src/widgets/ui_surfaces.dart';
import 'package:common_ui/src/widgets/ui_table.dart';
import 'package:material_ui/material_ui.dart';

/// Showcase of every token and widget of the design system, for development builds.
///
/// Sample content is a realistic switchboard, not lorem ipsum, so states can be judged in context.
class const UiGallery({
  /// Leaves the gallery.
  final VoidCallback? onBack,
  super.key,
}) extends StatefulWidget {
  @override
  State<UiGallery> createState() => _UiGalleryState();
}

class _UiGalleryState() extends State<UiGallery> {
  var _segment = 'standard';
  var _relay = true;
  var _spd = false;
  var _breaker = 16;
  var _choice = 0;

  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final double gutter = context.isExpandedLayout ? UiSpace.xl : UiSpace.l;
    final sections = <(String, Widget)>[
      ('Цвета', const _Swatches()),
      ('Типографика', const _TypeScale()),
      (
        'Кнопки',
        Wrap(
          spacing: UiSpace.s,
          runSpacing: UiSpace.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            UiButton(label: 'Создать проект', icon: UiIcons.add, onPressed: () {}),
            UiButton.secondary(label: 'Назад', icon: UiIcons.back, onPressed: () {}),
            UiButton.ghost(label: 'Добавить прибор', icon: UiIcons.add, onPressed: () {}),
            UiButton.danger(label: 'Удалить проект', onPressed: () {}),
            UiButton(label: 'Формируем PDF…', icon: UiIcons.report, busy: true, onPressed: () {}),
            const UiButton(label: 'Недоступно', onPressed: null),
            UiIconButton(icon: UiIcons.report, tooltip: 'Сохранить PDF', onPressed: () {}),
            UiIconButton(icon: UiIcons.moveLeft, tooltip: 'Сдвинуть влево', onPressed: () {}),
            UiIconButton(icon: UiIcons.moveUp, tooltip: 'На рейку выше', onPressed: () {}),
            UiIconButton(icon: UiIcons.moveDown, tooltip: 'На рейку ниже', onPressed: () {}),
            UiIconButton(icon: UiIcons.moveRight, tooltip: 'Сдвинуть вправо', onPressed: () {}),
            UiButton.secondary(label: 'Переставить', icon: UiIcons.rearrange, onPressed: () {}),
            UiMenuButton(
              tooltip: 'Ещё',
              entries: [
                UiMenuEntry(label: 'Дублировать', icon: UiIcons.copy, onPressed: () {}),
                UiMenuEntry(
                  label: 'Удалить',
                  icon: UiIcons.delete,
                  destructive: true,
                  onPressed: () {},
                ),
              ],
            ),
          ],
        ),
      ),
      (
        'Статусы',
        const Wrap(
          spacing: UiSpace.s,
          runSpacing: UiSpace.s,
          children: [
            UiBadge(label: 'Проверено', tone: UiTone.success),
            UiBadge(label: 'Требует проверки', tone: UiTone.warning),
            UiBadge(label: 'Не проходит', tone: UiTone.danger),
            UiBadge(label: 'Предварительно', tone: UiTone.neutral),
            UiBadge(label: 'Модулей DIN: 26', tone: UiTone.accent),
          ],
        ),
      ),
      (
        'Сообщения',
        const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiNotice(
              boxed: true,
              tone: UiTone.danger,
              message: 'Линия №8 не проходит проверку петли «фаза — нуль».',
            ),
            SizedBox(height: UiSpace.s),
            UiNotice(boxed: true, tone: UiTone.warning, message: 'ΔU 4,6 % больше 4 %.'),
            SizedBox(height: UiSpace.s),
            UiNotice(message: 'Сопротивление петли до щита не задано, расчёт с допущением.'),
          ],
        ),
      ),
      (
        'Поля',
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const UiTextField(
              label: 'Длина кабеля, м',
              numeric: true,
              help: 'От щита до самой дальней точки линии',
            ),
            const SizedBox(height: UiSpace.l),
            const UiTextField(
              label: 'Разрешённая мощность, кВт',
              numeric: true,
              error: 'Укажите значение больше 0',
            ),
            const SizedBox(height: UiSpace.l),
            UiSelect<int>(
              label: 'Номинал автомата, А',
              value: _breaker,
              options: const [(10, '10'), (16, '16'), (20, '20'), (25, '25'), (32, '32')],
              onChanged: (v) => setState(() => _breaker = v),
            ),
            const SizedBox(height: UiSpace.l),
            UiSegmented<String>(
              label: 'Сценарий',
              segments: const [
                UiSegment(value: 'economy', label: 'Эконом'),
                UiSegment(value: 'standard', label: 'Стандарт'),
                UiSegment(value: 'premium', label: 'Премиум'),
              ],
              selected: _segment,
              onChanged: (v) => setState(() => _segment = v),
            ),
          ],
        ),
      ),
      (
        'Строки',
        UiCard(
          child: UiDivided(
            children: [
              UiListRow(
                number: '1',
                title: 'Освещение комнат',
                subtitle: 'B10 · 3×1,5 мм² · 22 м',
                trailing: const UiQuantity('2,1', unit: 'А'),
                onTap: () {},
              ),
              UiListRow(
                number: '8',
                title: 'Кондиционер',
                subtitle: 'C20 · 3×2,5 мм² · 46 м',
                trailing: const UiQuantity('9,8', unit: 'А'),
                stripe: UiTone.danger,
                below: const UiBadge(label: 'Не проходит', tone: UiTone.danger),
                onTap: () {},
              ),
              UiSwitchRow(
                title: 'Реле напряжения',
                subtitle: 'Защищает технику от скачков в сети',
                value: _relay,
                onChanged: (v) => setState(() => _relay = v),
              ),
              UiSwitchRow(
                title: 'УЗИП',
                value: _spd,
                onChanged: (v) => setState(() => _spd = v),
              ),
              for (final (i, label) in const [(0, 'Подбирать автоматически'), (1, 'CHINT NXB-63')])
                UiChoiceRow(
                  title: label,
                  selected: _choice == i,
                  onTap: () => setState(() => _choice = i),
                ),
            ],
          ),
        ),
      ),
      (
        'Показатели',
        const UiCard(
          title: 'Ввод',
          trailing: UiBadge(label: 'Проверено', tone: UiTone.success),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UiMetricGrid(
                metrics: [
                  UiMetric(label: 'Расчётный ток', value: '45,5', unit: 'А'),
                  UiMetric(label: 'Вводной автомат', value: '50', unit: 'А'),
                  UiMetric(symbol: true, label: 'ΔU', value: '1,9', unit: '%'),
                  UiMetric(symbol: true, label: 'cos φ', value: '0,92'),
                ],
              ),
              UiKeyValueList(
                padding: EdgeInsets.all(UiSpace.l),
                entries: [('По приборам (Σ P·ku)', '17,42 кВт'), ('Разница токов фаз', '12 %')],
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(UiSpace.l, 0, UiSpace.l, UiSpace.l),
                child: UiRangeBar(position: .46, startLabel: '41 200 ₽', endLabel: '57 900 ₽'),
              ),
            ],
          ),
        ),
      ),
      (
        'Помещение',
        UiCard(
          banded: true,
          eyebrow: 'Кухня · 3',
          title: 'Кухня-гостиная',
          trailing: const UiQuantity('7,90', unit: 'кВт', style: UiTextStyles.reading),
          child: UiDivided(
            children: [
              for (final (name, count, kw) in const [
                ('Варочная панель', 1, '7,00'),
                ('Розетки рабочей зоны', 4, '0,20'),
                ('Освещение', 1, '0,10'),
              ])
                UiListRow(
                  dense: true,
                  title: name,
                  trailing: UiQuantity(kw, unit: 'кВт', prefix: count > 1 ? '$count ×' : null),
                  onTap: () {},
                ),
            ],
          ),
        ),
      ),
      (
        'Таблица',
        UiCard(
          child: UiTable(
            columns: const [
              UiTableColumn(label: '№', width: 48, numeric: true),
              UiTableColumn(label: 'Линия', flex: 3),
              UiTableColumn(label: 'Защита', flex: 2),
              UiTableColumn(label: 'Кабель', width: 112),
              UiTableColumn(label: 'Ток', width: 80, numeric: true),
              UiTableColumn(label: 'Статус', width: 156),
            ],
            rows: [
              for (final (n, name, rooms, breaker, device, cable, length, amps, tone, status)
                  in const [
                    (
                      '1',
                      'Освещение комнат',
                      'Спальня, детская',
                      'B10',
                      'Автомат',
                      '3×1,5',
                      '22 м',
                      '2,1',
                      UiTone.success,
                      'Проверено',
                    ),
                    (
                      '7',
                      'Тёплый пол',
                      'Ванная',
                      'C16',
                      'Дифавтомат · 30 мА, тип A',
                      '3×1,5',
                      '9 м',
                      '7,5',
                      UiTone.warning,
                      'Требует проверки',
                    ),
                    (
                      '8',
                      'Кондиционер',
                      'Гостиная',
                      'C20',
                      'Автомат',
                      '3×2,5',
                      '46 м',
                      '9,8',
                      UiTone.danger,
                      'Не проходит',
                    ),
                  ])
                UiTableRow(
                  onTap: () {},
                  stripe: tone == UiTone.success ? null : tone,
                  cells: [
                    Text(n, style: TextStyle(color: c.textMuted)),
                    UiTableCell(name, detail: rooms, strong: true),
                    UiTableDetail(
                      detail: device,
                      child: Text(breaker, style: UiTextStyles.valueStrong),
                    ),
                    UiTableDetail(
                      detail: length,
                      child: UiQuantity(cable, unit: 'мм²'),
                    ),
                    UiQuantity(amps, unit: 'А'),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: tone == UiTone.success
                          ? UiStatusIcon(tone: tone, label: status)
                          : UiBadge(label: status, tone: tone),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
      (
        'Раскрывающийся блок',
        const UiCard(
          child: UiDisclosure(
            title: 'Аппараты защиты',
            subtitle: '26 080 ₽ … 48 685 ₽',
            trailing: Text('34 795 ₽'),
            child: UiKeyValueList(
              padding: EdgeInsets.all(UiSpace.l),
              entries: [('Вводной автомат', '1 250 ₽'), ('№1 Освещение', '310 ₽')],
            ),
          ),
        ),
      ),
      (
        'Пустое состояние',
        UiCard(
          child: UiEmptyState(
            standalone: false,
            icon: UiIcons.rooms,
            title: 'Помещений пока нет',
            message: 'Добавьте помещения, и линии посчитаются автоматически.',
            actions: [UiButton(label: 'Добавить помещение', icon: UiIcons.add, onPressed: () {})],
          ),
        ),
      ),
      (
        'Окна',
        Wrap(
          spacing: UiSpace.s,
          runSpacing: UiSpace.s,
          children: [
            UiButton.secondary(
              label: 'Открыть лист',
              onPressed: () => showUiSheet<void>(
                context,
                builder: (context) => UiSheet(
                  title: 'Новый проект',
                  body: const SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(UiSpace.xl, 0, UiSpace.xl, UiSpace.xl),
                    child: UiTextField(label: 'Название'),
                  ),
                  actions: [
                    UiButton.secondary(
                      label: 'Отмена',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    UiButton(label: 'Создать', onPressed: () => Navigator.of(context).pop()),
                  ],
                ),
              ),
            ),
            UiButton.secondary(
              label: 'Подтверждение удаления',
              onPressed: () => showUiConfirm(
                context,
                title: 'Удалить проект «Дача»?',
                message: 'Проект, его помещения, линии и смета будут удалены.',
                confirmLabel: 'Удалить проект',
                cancelLabel: 'Отмена',
              ),
            ),
            UiButton.secondary(
              label: 'Уведомление',
              onPressed: () => showUiToast(
                context,
                message: 'Проект «Дача» импортирован',
                actionLabel: 'Открыть',
                onAction: () {},
              ),
            ),
          ],
        ),
      ),
    ];
    return Scaffold(
      appBar: UiTopBar(
        title: 'Компоненты интерфейса',
        eyebrow: 'Чертёж',
        leading: widget.onBack == null
            ? null
            : UiIconButton(
                icon: UiIcons.back,
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: widget.onBack,
              ),
      ),
      body: ListView(
        padding: EdgeInsets.all(gutter),
        children: [
          UiContentWidth(
            maxWidth: 960,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (title, child) in sections) ...[
                  UiSectionHeader(title),
                  child,
                  const SizedBox(height: UiSpace.xxl),
                ],
                Text(
                  'Тема меняется в настройках приложения.',
                  style: UiTextStyles.caption.copyWith(color: c.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class const _Swatches() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final roles = <(String, Color)>[
      ('canvas', c.canvas),
      ('surface', c.surface),
      ('sunken', c.sunken),
      ('border', c.border),
      ('borderStrong', c.borderStrong),
      ('text', c.text),
      ('textMuted', c.textMuted),
      ('primary', c.primary),
      ('accent', c.accent),
      ('success', c.success),
      ('warning', c.warning),
      ('danger', c.danger),
    ];
    return Wrap(
      spacing: UiSpace.s,
      runSpacing: UiSpace.s,
      children: [
        for (final (name, color) in roles) _Swatch(name: name, color: color, colors: c),
      ],
    );
  }
}

class const _Swatch({
  required final String name,
  required final Color color,
  required final UiColors colors,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String hex = color.toARGB32().toRadixString(16).substring(2).toUpperCase();
    return SizedBox(
      width: 128,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border.all(color: colors.border),
          borderRadius: UiRadius.controlAll,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 44, child: ColoredBox(color: color)),
            Padding(
              padding: const EdgeInsets.all(UiSpace.s),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: UiTextStyles.caption.copyWith(color: colors.text)),
                  Text(
                    '#$hex',
                    style: UiTextStyles.value.copyWith(color: colors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class const _TypeScale() extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final UiColors c = context.uiColors;
    final styles = <(String, TextStyle, String)>[
      ('display 28', UiTextStyles.display, 'Щит на 36 модулей'),
      ('title 20', UiTextStyles.title, 'Розетки, кухня'),
      ('heading 16', UiTextStyles.heading, 'Параметры линии'),
      ('body 16', UiTextStyles.body, 'Сечение подобрано по допустимому току.'),
      ('bodySmall 14', UiTextStyles.bodySmall, 'Автомат C16 · 3×2,5 мм² · 28 м'),
      ('caption 13', UiTextStyles.caption, 'Из технических условий на присоединение'),
      ('label 12', UiTextStyles.label, 'РАСЧЁТНЫЙ ТОК'),
      ('value 14', UiTextStyles.value, '45,5 А · ΔU 1,9 % · 48 600 ₽'),
      ('reading 20', UiTextStyles.reading, '10,0 кВт'),
      ('readingLarge 28', UiTextStyles.readingLarge, '≈ 48 600 ₽'),
    ];
    return UiCard(
      child: UiDivided(
        children: [
          for (final (name, style, sample) in styles)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: UiSpace.l, vertical: UiSpace.m),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  SizedBox(width: 128, child: UiLabel(name, symbol: true)),
                  Expanded(
                    child: Text(sample, style: style.copyWith(color: c.text)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
