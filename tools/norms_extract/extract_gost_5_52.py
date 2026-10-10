"""Extracts tables of ГОСТ Р 50571.5.52-2011 (IEC 60364-5-52:2009, IDT) into norms_data JSON.

Source: text version of the standard (meganorm.ru), stored locally as
reference/norms_src/gost_5_52_2011.htm (not committed: third-party text).

Usage: python3 -I tools/norms_extract/extract_gost_5_52.py <gost_5_52_2011.htm> <out_dir>

Known defects of the text version are corrected explicitly via ERRATA and reported in the output,
so every deviation from the source text is visible and can be checked against the scan.
"""
import json
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import html_tables  # noqa: E402

DOCUMENT = "gost-r-50571-5-52-2011"
DATASET_VERSION = "2026.10-1"

SECTIONS = [1.5, 2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120, 150, 185, 240, 300]
METHODS_ABCD = ["A1", "A2", "B1", "B2", "C", "D1", "D2"]

# (table id, insulation, loaded conductors, max conductor temperature, caption fragment)
ABCD_TABLES = [
    ("B.52.2", "pvc", 2, 70, "PVC изоляция для двух нагруженных"),
    ("B.52.3", "xlpe", 2, 90, "EPR изоляция для двух нагруженных"),
    ("B.52.4", "pvc", 3, 70, "PVC изоляция для трех нагруженных"),
    ("B.52.5", "xlpe", 3, 90, "EPR изоляция для трех нагруженных"),
]
# Method E (multicore cable in free air / perforated tray): columns 2 (two loaded) and 3 (three loaded).
E_TABLES = [
    ("B.52.10", "pvc", "copper", "PVC изоляция, медные"),
    ("B.52.11", "pvc", "aluminium", "PVC изоляция, алюминиевые"),
    ("B.52.12", "xlpe", "copper", "EPR изоляция, медные"),
    ("B.52.13", "xlpe", "aluminium", "EPR изоляция, алюминиевые"),
]

# Corrections of evident defects of the text version. Each must be confirmed against the scan
# at the verification stage (see verification/VERIFICATION.md).
ERRATA = [
    {
        "table": "B.52.12", "material": "copper", "method": "E", "loaded_conductors": 3,
        "section_mm2": 50, "text_value": 102, "used_value": 192,
        "reason": "Non-monotonic in the text version (35 mm2: 158 A, 70 mm2: 246 A); "
                  "IEC 60364-5-52:2009 Table B.52.12 gives 192 A.",
    },
]


def num(cell):
    """Parses a table cell like '14,5', '1 005', '-' or '' into float or None."""
    s = cell.replace(" ", "").replace(" ", "").replace(",", ".").strip()
    if s in ("", "-", "_"):
        return None
    return float(s)


def find_table(tables, *fragments):
    for t in tables:
        if all(f in t["caption"][-400:] for f in fragments):
            return t
    raise LookupError(f"table not found: {fragments}")


def rows_by_material(table):
    """Splits rows of a B.52.2-5 table into {'copper': [...], 'aluminium': [...]}."""
    result, current = {"copper": [], "aluminium": []}, None
    for r in table["rows"]:
        head = r[0].strip()
        if head.startswith("Медь"):
            current = "copper"
        elif head.startswith("Алюминий"):
            current = "aluminium"
        elif current and head and head[0].isdigit() and len(r) >= 8:
            result[current].append(r)
    return result


def section_column(rows, col):
    by_section = {num(r[0]): num(r[col]) for r in rows}
    return [by_section.get(s) for s in SECTIONS]


def apply_errata(columns, applied):
    for e in ERRATA:
        for c in columns:
            if (c["table"], c["material"], c["method"], c["loaded_conductors"]) == (
                e["table"], e["material"], e["method"], e["loaded_conductors"]
            ):
                i = SECTIONS.index(e["section_mm2"])
                assert c["values_a"][i] == e["text_value"], (e, c["values_a"][i])
                c["values_a"][i] = e["used_value"]
                applied.append(e)


def ampacity(tables):
    columns = []
    for table_id, insulation, loaded, temp, fragment in ABCD_TABLES:
        t = find_table(tables, fragment)
        for material, rows in rows_by_material(t).items():
            for i, method in enumerate(METHODS_ABCD):
                columns.append({
                    "table": table_id, "column": i + 2, "insulation": insulation,
                    "material": material, "loaded_conductors": loaded, "method": method,
                    "max_conductor_temp_c": temp, "values_a": section_column(rows, i + 1),
                })
    for table_id, insulation, material, fragment in E_TABLES:
        t = find_table(tables, "F и G", fragment)
        rows = [r for r in t["rows"] if r and r[0][:1].isdigit() and len(r) == 8 and num(r[0]) in SECTIONS]
        for loaded, col in ((2, 1), (3, 2)):
            columns.append({
                "table": table_id, "column": col + 1, "insulation": insulation,
                "material": material, "loaded_conductors": loaded, "method": "E",
                "max_conductor_temp_c": 70 if insulation == "pvc" else 90,
                "values_a": section_column(rows, col),
            })
    applied = []
    apply_errata(columns, applied)
    return {
        "dataset": "ampacity",
        "dataset_version": DATASET_VERSION,
        "description": "Допустимые длительные токи (А) для одной цепи по способам монтажа.",
        "source": {"documents": [DOCUMENT], "tables": [t[0] for t in ABCD_TABLES] + [t[0] for t in E_TABLES]},
        "conditions": {"air_ambient_c": 30, "ground_ambient_c": 20, "soil_thermal_resistivity_k_m_per_w": 2.5,
                       "ground_depth_m": 0.7},
        "notes": [
            "Метод E — многожильный кабель в воздухе/на перфорированном лотке (графы 2–3 таблиц B.52.10–B.52.13).",
            "Для алюминия значения начинаются с 2,5 мм²; null — нет данных в таблице.",
            "Примечание к таблицам: круглые проводники до 16 мм² включительно, далее — секторные (допускается применять к круглым).",
        ],
        "sections_mm2": SECTIONS,
        "columns": columns,
        "errata": applied,
    }


def temperature_factors(tables):
    t = find_table(tables, "проложенных в воздухе при температуре окружающей среды, отличной от 30")
    steps, pvc, xlpe = [], [], []
    for r in t["rows"]:
        if r and r[0].isdigit() and len(r) >= 3:
            steps.append(int(r[0]))
            pvc.append(num(r[1]))
            xlpe.append(num(r[2]))
    g = find_table(tables, "проложенных в трубах в земле при температуре грунта, отличной от 20")
    ground = {}
    for r in g["rows"]:
        if r and r[0].isdigit() and len(r) >= 6:
            ground[int(r[0])] = (num(r[1]), num(r[2]))
            ground[int(r[3])] = (num(r[4]), num(r[5]))
    gsteps = sorted(ground)
    return {
        "dataset": "temperature_factors",
        "dataset_version": DATASET_VERSION,
        "description": "Поправочные коэффициенты на температуру окружающей среды (воздух) и грунта.",
        "source": {"documents": [DOCUMENT], "tables": ["B.52.14", "B.52.15"]},
        "notes": [
            "Опорная температура (коэффициент 1,0) в таблицах не приводится и добавлена явно: 30 °C воздух, 20 °C грунт.",
            "Минеральная изоляция не используется и не переносилась.",
        ],
        "air": {"reference_c": 30, "steps_c": sorted(steps + [30]),
                "pvc": _with_reference(steps, pvc, 30), "xlpe": _with_reference(steps, xlpe, 30)},
        "ground": {"reference_c": 20, "steps_c": sorted(gsteps + [20]),
                   "pvc": _with_reference(gsteps, [ground[s][0] for s in gsteps], 20),
                   "xlpe": _with_reference(gsteps, [ground[s][1] for s in gsteps], 20)},
    }


def _with_reference(steps, values, reference):
    merged = dict(zip(steps, values))
    merged[reference] = 1.0
    return [merged[s] for s in sorted(merged)]


def soil_factors(tables):
    t = find_table(tables, "2,5 К·м/Вт")
    header = [num(c) for c in t["rows"][0][1:]]
    duct = [num(c) for c in t["rows"][1][1:]]
    direct = [num(c) for c in t["rows"][2][1:]]
    return {
        "dataset": "soil_resistivity_factors",
        "dataset_version": DATASET_VERSION,
        "description": "Поправочные коэффициенты на удельное тепловое сопротивление грунта (методы D1, D2).",
        "source": {"documents": [DOCUMENT], "tables": ["B.52.16"]},
        "notes": ["Усреднённые значения, погрешность ±5 %, глубина прокладки до 0,8 м."],
        "resistivity_k_m_per_w": header,
        "in_duct": duct,
        "direct_in_ground": direct,
    }


def grouping_factors(tables):
    t = find_table(tables, "используются применительно с допустимыми токовыми нагрузками")
    counts = [int(c) for c in t["rows"][1]]
    rows = []
    keys = {"1": "bunched", "2": "single_layer_on_wall", "3": "single_layer_under_ceiling",
            "4": "single_layer_perforated_tray", "5": "single_layer_ladder"}
    for r in t["rows"][2:7]:
        vals = []
        for c in r[2:2 + len(counts)]:
            try:
                vals.append(num(c))
            except ValueError:  # reference to applicable tables ends the numeric part
                break
        vals += [None] * (len(counts) - len(vals))
        rows.append({"item": int(r[0]), "arrangement": keys[r[0]], "description": r[1], "factors": vals})

    d2 = find_table(tables, "способ D2 таблиц")
    d2_rows = [r for r in d2["rows"] if r and r[0].isdigit()]
    d1a = find_table(tables, "способ D1 таблицы", "Понижающие")
    d1_rows = []
    for r in d1a["rows"]:
        if r and r[0].isdigit() and len(r) >= 10:
            d1_rows.append(r[0:5])
            if r[5].strip():
                d1_rows.append(r[5:10])
    errata = []
    fixed = []
    for r in d1_rows:
        n = int(r[0])
        if n == 16 and any(int(x[0]) == 16 for x in fixed):
            errata.append({"table": "B.52.19 A", "text_value": "16", "used_value": "18",
                           "reason": "Число кабелей «16» повторяется дважды; по порядку строк (17, ?, 19) это 18."})
            n = 18
        fixed.append([str(n)] + r[1:])
    fixed.sort(key=lambda r: int(r[0]))
    return {
        "dataset": "grouping_factors",
        "dataset_version": DATASET_VERSION,
        "description": "Понижающие коэффициенты для групп цепей или многожильных кабелей.",
        "source": {"documents": [DOCUMENT], "tables": ["B.52.17", "B.52.18", "B.52.19"]},
        "notes": [
            "B.52.17: для однотипных, одинаково нагруженных кабелей; null — коэффициент не применяется/нет данных.",
            "Для числа цепей между столбцами принимается ближайший больший столбец (консервативно).",
            "B.52.18, B.52.19: глубина 0,7 м, грунт 2,5 К·м/Вт.",
        ],
        "air": {"table": "B.52.17", "counts": counts, "arrangements": rows},
        "direct_in_ground": {
            "table": "B.52.18", "spacing": ["touching", "one_diameter", "0.125m", "0.25m", "0.5m"],
            "counts": [int(r[0]) for r in d2_rows],
            "factors": [[num(c) for c in r[1:6]] for r in d2_rows],
        },
        "in_ducts_multicore": {
            "table": "B.52.19 A", "spacing": ["touching", "0.25m", "0.5m", "1.0m"],
            "counts": [int(r[0]) for r in fixed],
            "factors": [[num(c) for c in r[1:5]] for r in fixed],
        },
        "errata": errata,
    }


def voltage_drop(tables):
    t = find_table(tables, "Таблица G.52.1")
    a, b = t["rows"][1], t["rows"][2]
    return {
        "installation_type_a_public_lv_supply": {"lighting_percent": num(a[1]), "other_percent": num(a[2])},
        "installation_type_b_private_lv_supply": {"lighting_percent": num(b[1]), "other_percent": num(b[2])},
    }


def main():
    src, out = sys.argv[1], sys.argv[2]
    tables = html_tables.extract(src)
    os.makedirs(out, exist_ok=True)
    datasets = {
        "ampacity.json": ampacity(tables),
        "temperature_factors.json": temperature_factors(tables),
        "soil_resistivity_factors.json": soil_factors(tables),
        "grouping_factors.json": grouping_factors(tables),
    }
    for name, data in datasets.items():
        with open(os.path.join(out, name), "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=1)
            f.write("\n")
    print(json.dumps({"G.52.1": voltage_drop(tables)}, ensure_ascii=False))


if __name__ == "__main__":
    main()
