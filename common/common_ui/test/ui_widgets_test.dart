import 'package:common_ui/common_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _app(Widget child, {Size size = const Size(400, 800)}) => MaterialApp(
  theme: UiTheme.light,
  home: MediaQuery(
    data: MediaQueryData(size: size),
    child: Scaffold(body: Center(child: child)),
  ),
);

void main() {
  group('UiButton', () {
    testWidgets('calls onPressed on tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_app(UiButton(label: 'Создать', onPressed: () => taps++)));
      await tester.tap(find.text('Создать'));
      expect(taps, 1);
    });

    testWidgets('ignores taps while busy and when disabled', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              UiButton(label: 'Занята', busy: true, onPressed: () => taps++),
              const UiButton(label: 'Выключена', onPressed: null),
            ],
          ),
        ),
      );
      await tester.tap(find.text('Занята'));
      await tester.tap(find.text('Выключена'));
      expect(taps, 0);
    });

    testWidgets('activates with Enter when focused', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        _app(UiButton(label: 'Сохранить', autofocus: true, onPressed: () => taps++)),
      );
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(taps, 1);
    });

    testWidgets('keeps the 44px touch target when small', (tester) async {
      await tester.pumpWidget(_app(UiButton(label: 'Ещё', small: true, onPressed: () {})));
      expect(tester.getSize(find.byType(UiButton)).height, UiSize.control);
    });
  });

  testWidgets('UiIconButton exposes its tooltip as the label', (tester) async {
    final SemanticsHandle semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      _app(UiIconButton(icon: UiIcons.report, tooltip: 'Сохранить PDF', onPressed: () {})),
    );
    expect(find.bySemanticsLabel('Сохранить PDF'), findsOneWidget);
    expect(tester.getSize(find.byType(UiIconButton)), const Size.square(UiSize.control));
    semantics.dispose();
  });

  testWidgets('UiSegmented reports the tapped value', (tester) async {
    String? selected;
    await tester.pumpWidget(
      _app(
        UiSegmented<String>(
          segments: const [
            UiSegment(value: 'board', label: 'Щит'),
            UiSegment(value: 'list', label: 'Список'),
          ],
          selected: 'board',
          onChanged: (v) => selected = v,
        ),
      ),
    );
    await tester.tap(find.text('Список'));
    expect(selected, 'list');
  });

  testWidgets('UiSwitchRow toggles from anywhere in the row', (tester) async {
    bool? value;
    await tester.pumpWidget(
      _app(UiSwitchRow(title: 'Реле напряжения', value: false, onChanged: (v) => value = v)),
    );
    await tester.tap(find.text('Реле напряжения'));
    expect(value, isTrue);
  });

  testWidgets('UiSelect opens the options and reports the choice', (tester) async {
    int? value;
    await tester.pumpWidget(
      _app(
        SizedBox(
          width: 300,
          child: UiSelect<int>(
            label: 'Номинал автомата, А',
            value: 16,
            options: const [(10, '10'), (16, '16'), (25, '25')],
            onChanged: (v) => value = v,
          ),
        ),
      ),
    );
    await tester.tap(find.text('16'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('25').last);
    await tester.pumpAndSettle();
    expect(value, 25);
  });

  testWidgets('UiDisclosure shows the content only when expanded', (tester) async {
    await tester.pumpWidget(
      _app(const UiDisclosure(title: 'Предупреждения', child: Text('Содержимое'))),
    );
    expect(find.text('Содержимое'), findsNothing);
    await tester.tap(find.text('Предупреждения'));
    await tester.pumpAndSettle();
    expect(find.text('Содержимое'), findsOneWidget);
  });

  group('UiTable', () {
    Widget table(VoidCallback onTap) => UiTable(
      minWidth: 600,
      columns: const [
        UiTableColumn(label: '№', width: 48, numeric: true),
        UiTableColumn(label: 'Линия'),
      ],
      rows: [
        UiTableRow(onTap: onTap, cells: const [Text('1'), Text('Освещение')]),
      ],
    );

    testWidgets('opens a row on tap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_app(table(() => taps++), size: const Size(1000, 800)));
      await tester.tap(find.text('Освещение'));
      expect(taps, 1);
    });

    testWidgets('scrolls horizontally when narrower than minWidth', (tester) async {
      await tester.pumpWidget(_app(SizedBox(width: 360, child: table(() {}))));
      expect(
        find.descendant(of: find.byType(UiTable), matching: find.byType(SingleChildScrollView)),
        findsOneWidget,
      );
    });
  });

  group('showUiConfirm', () {
    Future<bool?> run(WidgetTester tester, String button) async {
      bool? result;
      await tester.pumpWidget(
        _app(
          Builder(
            builder: (context) => UiButton(
              label: 'Удалить',
              onPressed: () async => result = await showUiConfirm(
                context,
                title: 'Удалить проект «Дача»?',
                message: 'Действие нельзя отменить.',
                confirmLabel: 'Удалить проект',
                cancelLabel: 'Отмена',
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Удалить'));
      await tester.pumpAndSettle();
      await tester.tap(find.text(button));
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets('returns true on confirm', (tester) async {
      expect(await run(tester, 'Удалить проект'), isTrue);
    });

    testWidgets('returns false on cancel', (tester) async {
      expect(await run(tester, 'Отмена'), isFalse);
    });
  });

  testWidgets('UiTopBar grows by the height of its bottom part', (tester) async {
    const bar = UiTopBar(
      title: 'Проект',
      bottom: UiStepBar(steps: [], onSelected: _ignore),
    );
    expect(bar.preferredSize.height, 56 + UiStepBar.height);
  });
}

void _ignore(int _) {}
