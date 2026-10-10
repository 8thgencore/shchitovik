# norms_data

Нормативные таблицы и справочники «Щитовика» как данные с указанием источника каждой таблицы.
Чистый Dart, без I/O во время работы: JSON встраивается в код (`lib/src/generated/`).

## Наборы данных (`data/*.json`)

| Файл | Источник | Как получен |
|---|---|---|
| `ampacity.json` | ГОСТ Р 50571.5.52-2011, табл. B.52.2–B.52.5, B.52.10–B.52.13 | `tools/norms_extract/extract_gost_5_52.py` |
| `temperature_factors.json` | там же, B.52.14–B.52.15 | то же |
| `soil_resistivity_factors.json` | там же, B.52.16 | то же |
| `grouping_factors.json` | там же, B.52.17–B.52.19 | то же |
| `sp256_residential_loads.json` | СП 256, табл. 7.1–7.3, 7.5а, п. 7.1.12 | `tools/norms_extract/extract_sp256.py` |
| `sp256_public_loads.json` | СП 256, табл. 7.5–7.14 | то же |
| `min_cross_sections.json` | СП 256, табл. 15.3, пп. 10.2, 15.3 | то же |
| `conductors.json` | ГОСТ 22483, ГОСТ Р 50571.5.54 табл. A.54.1 | вручную |
| `protective_conductors.json` | ГОСТ Р 50571.5.54 табл. 54.2, A.54.4 | вручную |
| `breakers.json` | ГОСТ IEC 60898-1 | вручную |
| `disconnection_times.json` | ГОСТ Р 50571.4.41-2022 табл. 41.1, ПУЭ 1.7.79 | вручную |
| `voltage_drop_limits.json` | СП 256 п. 8.23, ГОСТ Р 50571.5.52 G.52.1 | вручную |
| `electrical_constants.json` | СП 256 п. 8.23, ГОСТ 32144, ГОСТ 29322 | вручную |
| `installation_methods.json` | ГОСТ Р 50571.5.52 табл. A.52.3, B.52.1 | вручную |
| `device_catalog.json`, `room_templates.json` | инженерная оценка | `tools/norms_extract/build_reference_catalogs.py` |
| `documents.json` | реестр документов, статусы и открытые вопросы | вручную |

Каждый набор содержит `dataset_version` и `source.documents` (ссылки на `documents.json`).
Исправления опечаток текстовой версии норм перечислены в поле `errata` соответствующего набора.

## Правила поиска по таблицам

- Между ступенями температуры, числа цепей и теплового сопротивления грунта берётся следующая
  (менее благоприятная) ступень — консервативно.
- Таблицы СП 256 интерполируются линейно, как предписывают их примечания.
- `null` — в таблице нет значения; решение принимает `electrical_core`.

## Обновление данных

```bash
# исходные тексты норм лежат локально в reference/norms_src/ (не в git)
python3 -I tools/norms_extract/extract_gost_5_52.py reference/norms_src/gost_5_52_2011.htm engine/norms_data/data
python3 -I tools/norms_extract/extract_sp256.py reference/norms_src/sp256.docx engine/norms_data/data
python3 -I tools/norms_extract/build_reference_catalogs.py engine/norms_data/data
cd engine/norms_data && dart run tool/embed_data.dart && dart test
```

Тест `embedded_datasets_test.dart` падает, если встроенная копия устарела.
