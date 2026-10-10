# electrical_core

Расчётное ядро «Щитовика» на чистом Dart. Одна точка входа:

```dart
final result = calculateProject(input); // ProjectInput → ProjectResult
```

Функция чистая и детерминированная. В базе хранится только `ProjectInput` (JSON — `toJson`/`fromJson`),
результат всегда пересчитывается. `algorithmVersion` меняется при любом изменении, влияющем на результат.

## Порядок расчёта

1. Проверка ввода (помещения, мощности, cos φ, трёхфазные приборы на однофазном вводе).
2. Группы (`calc/circuit_builder.dart`): выделенные линии, освещение по зонам, розетки по помещениям.
3. Токи (`calc/currents.dart`): IB с Kс = 1, ожидаемый ток с ku, пусковой ток.
4. Баланс фаз (`calc/phase_balancer.dart`) при трёхфазном вводе.
5. Нагрузка ввода по приборам и по СП 256 (`calc/demand_calculator.dart`), вводной автомат, кабель ввода.
6. Автомат и характеристика, УЗО (`calc/protection_selector.dart`).
7. Кабель (`calc/cable_calculator.dart`): Iz, ΔU (прил. G ГОСТ Р 50571.5.52), петля «фаза — PE», PE.
8. Групповые и противопожарное УЗО, статусы.

Каждое правило ссылается на пункт нормы в коде и в `Check.reference`. Формулы и допущения —
в [verification/VERIFICATION.md](../../verification/VERIFICATION.md).

## Демо-проекты

`DemoProjects.oneRoomApartment()`, `threeRoomApartment()`, `house()`; сводка: `dart run tool/print_demo.dart`.
