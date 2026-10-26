"""Extracts load tables of СП 256.1325800.2016 (ред. 01.03.2022, изм. 1–5) into norms_data JSON.

Source: ConsultantPlus export (.docx) stored locally as reference/norms_src/sp256.docx (not committed).

Usage: python3 -I tools/norms_extract/extract_sp256.py <sp256.docx> <out_dir>
"""
import json
import os
import re
import sys
import xml.etree.ElementTree as ET
import zipfile

DOCUMENT = "sp-256-1325800-2016"
DATASET_VERSION = "2026.10-1"
W = "{http://schemas.openxmlformats.org/wordprocessingml/2006/main}"


def _text(el):
    return "".join(t.text or "" for t in el.iter(W + "t"))


def tables_by_caption(path):
    """Returns {'Таблица 7.1': [[cells]], ...}; a table is attributed to the nearest preceding caption."""
    body = ET.fromstring(zipfile.ZipFile(path).read("word/document.xml")).find(W + "body")
    result, caption = {}, None
    for el in body:
        if el.tag == W + "p":
            s = _text(el).strip()
            m = re.match(r"^Таблица (\d+\.\d+а?(\.\d+)?)$", s)
            if m:
                caption = "Таблица " + m.group(1)
        elif el.tag == W + "tbl" and caption:
            rows = []
            for tr in el.iter(W + "tr"):
                cells = []
                for tc in tr.findall(W + "tc"):
                    vmerge = tc.find(f"{W}tcPr/{W}vMerge")
                    if vmerge is not None and vmerge.get(W + "val") != "restart":
                        cells.append("^")  # continuation of a vertically merged cell
                    else:
                        cells.append(re.sub(r"\s+", " ", " ".join(_text(p) for p in tc.findall(W + "p"))).strip())
                rows.append(cells)
            # Drop ConsultantPlus remark rows (and remark-only boxes); the real table follows.
            rows = [r for r in rows if not any("КонсультантПлюс" in c for c in r)]
            if not rows:
                continue
            result.setdefault(caption, rows)
    return result


def num(cell):
    s = cell.replace(" ", "").replace(" ", "").replace(",", ".").strip()
    if s in ("", "-"):
        return None
    return float(s)


def row_starting(rows, prefix):
    return next(r for r in rows if r and r[0].startswith(prefix))


def residential(t):
    t71 = t["Таблица 7.1"]
    counts = [c for c in t71[1][1:]]
    apartments = [int(c.split("-")[0].strip()) if "-" in c else int(c) for c in counts]
    stove = {
        "natural_gas": row_starting(t71, "1 Квартиры с плитами"),
        "liquefied_gas_or_solid_fuel": row_starting(t71, "- на сжиженном газе"),
        "electric_8_5_kw": row_starting(t71, "- электрическими"),
        "summer_cottages": row_starting(t71, "2 Летние домики"),
    }
    t72 = t["Таблица 7.2"]
    t73 = t["Таблица 7.3"]
    t75a = t["Таблица 7.5а"]
    kpk = []
    current = None
    for r in t75a[1:]:
        if r[0].isdigit():
            value = num(r[2]) if len(r) > 2 and r[2] not in ("", "^") else current
            current = value
            kpk.append({"group": int(r[0]), "regions": r[1], "k": value})
    return {
        "dataset": "sp256_residential_loads",
        "dataset_version": DATASET_VERSION,
        "description": "Расчётные нагрузки жилых зданий (СП 256, раздел 7.1).",
        "source": {"documents": [DOCUMENT], "tables": ["7.1", "7.2", "7.3", "7.5а"], "clauses": ["7.1.2", "7.1.10", "7.1.12"]},
        "notes": [
            "Табл. 7.1: удельные нагрузки для квартир средней площадью 70 м² (35–90 м²), типовые проекты; "
            "учтено общедомовое освещение (прим. 2); не учтены электроотопление, электроводонагреватели "
            "и бытовые кондиционеры (прим. 6). Промежуточные значения – интерполяцией (прим. 1).",
            "Прим. 4: квартиры повышенной комфортности – по заявленной мощности с Kс (табл. 7.2) и Kо (табл. 7.3).",
            "Прим. 11 (изм. 4): одноквартирный дом 55–300 м² с газовой плитой – по строке «природный газ», "
            "с электроплитой или электросауной – по строке «электрические плиты».",
        ],
        "specific_load_kw_per_apartment": {
            "table": "7.1",
            "apartments": apartments,
            "rows": {k: [num(c) for c in r[1:]] for k, r in stove.items()},
        },
        "comfort_demand_factor": {
            "table": "7.2",
            "declared_power_kw": [14, 20, 30, 40, 50, 60, 70],
            "kc": [num(c) for c in t72[1][1:]],
            "notes": ["Первый столбец – «до 14 кВт», последний – «70 и более»."],
        },
        "comfort_simultaneity_factor": {
            "table": "7.3",
            "apartments": [int(c.split("-")[0].strip().split()[0]) for c in t73[1][1:]],
            "ko_electric_stoves": [num(c) for c in t73[2][1:]],
        },
        "regional_correction_kpk": {"table": "7.5а", "groups": kpk},
        "power_factor": {
            "clause": "7.1.12",
            "apartments_electric_stoves": 0.98,
            "apartments_electric_stoves_with_air_conditioners": 0.93,
            "apartments_gas_or_solid_fuel_stoves": 0.96,
            "apartments_gas_or_solid_fuel_stoves_with_air_conditioners": 0.92,
            "sanitary_pumps_ventilation": 0.8,
            "lifts": 0.65,
        },
    }


def public(t):
    t75 = t["Таблица 7.5"]
    sanitary = []
    for r in t75[2:]:
        if r[0].isdigit():
            sanitary.append({"share_percent": r[1],
                             "kc": [num(re.sub(r"\s*\(.*\)", "", c)) for c in r[2:]],
                             "kc_motor_over_30kw": [num(m.group(1)) if (m := re.search(r"\(([\d,]+)\)", c)) else None
                                                    for c in r[2:]]})
    t76 = t["Таблица 7.6"]
    lighting = [{"item": int(r[0]), "organization": r[1], "kc": [num(c) for c in r[2:]]}
                for r in t76[2:] if r and r[0].isdigit()]
    t77 = t["Таблица 7.7"]
    sockets = [{"item": int(r[0]), "organization": r[1],
                "kc_group": num(r[2]), "kc_feeder": num(r[3]), "kc_building_input": num(r[4])}
               for r in t77[2:] if r and r[0].isdigit()]
    t78 = t["Таблица 7.8"]
    power = []
    for r in t78[2:]:
        if r and r[0].isdigit():
            def val(c):
                try:
                    return num(c)
                except ValueError:
                    return c
            power.append({"item": int(r[0]), "loads": r[1], "kc_up_to_3": val(r[2]), "kc_over_5": val(r[3])})
    t79 = t["Таблица 7.9"]
    t710 = t["Таблица 7.10"]
    t711 = t["Таблица 7.11"]
    mismatch = [{"item": int(r[0]), "building": r[1], "k": r[2:5]} for r in t711[2:] if r and r[0].isdigit()]
    t712 = t["Таблица 7.12"]
    pf = [{"consumer": r[0], "cos_phi": r[1]} for r in t712[1:] if len(r) > 1 and r[1]]
    t714 = t["Таблица 7.14"]
    # Item ranges of the table's group headers (rows 25–27 and 19–20 have no header of their own).
    groups = [(1, 6, "Предприятия общественного питания"), (7, 8, "Продовольственные магазины"),
              (9, 10, "Промтоварные магазины"), (11, 15, "Общеобразовательные школы"),
              (16, 16, None), (17, 18, "Кинотеатры и киноконцертные залы"), (19, 20, None),
              (21, 22, "Здания или помещения учреждений управления, проектных и конструкторских организаций"),
              (23, 24, "Гостиницы"), (25, 27, None)]
    specific, unit = [], None
    for r in t714[1:]:
        if r and r[0].isdigit() and len(r) >= 4:
            item = int(r[0])
            unit = unit if r[2] in ("^", "") else r[2]
            group = next(g for lo, hi, g in groups if lo <= item <= hi)
            specific.append({"item": item, "group": group, "building": r[1],
                             "unit": unit if r[2] in ("^", "") else r[2], "specific_load": num(r[3])})
    return {
        "dataset": "sp256_public_loads",
        "dataset_version": DATASET_VERSION,
        "description": "Расчётные нагрузки общественных зданий (СП 256, раздел 7.2) и Kс сантехнического оборудования (табл. 7.5).",
        "source": {"documents": [DOCUMENT], "tables": ["7.5", "7.6", "7.7", "7.8", "7.9", "7.10", "7.11", "7.12", "7.14"],
                   "clauses": ["7.2.1", "7.2.4", "7.2.6", "7.2.7", "7.2.16", "7.2.18", "7.2.20"]},
        "notes": [
            "Промежуточные значения Kс – интерполяцией (примечания к таблицам).",
            "Табл. 7.8, прим. 1: расчётная нагрузка не менее мощности наибольшего электроприёмника; прим. 2: для одного электроприёмника Kс = 1.",
            "Табл. 7.11 хранится как текст ячеек: в скобках значения для зданий с кондиционированием.",
            "Табл. 7.12 хранится как текст ячеек (есть диапазоны вида «0,3 - 0,5»).",
        ],
        "sanitary_demand_factor": {"table": "7.5", "receivers": [int(c) for c in t75[1][2:]], "rows": sanitary},
        "lighting_demand_factor": {"table": "7.6", "installed_kw": [5, 10, 15, 25, 50, 100, 200, 400, 500],
                                   "rows": lighting,
                                   "notes": ["Первый столбец – «до 5 кВт», последний – «св. 500 кВт»."]},
        "socket_demand_factor": {"table": "7.7", "socket_power_kw": 0.06, "rows": sockets},
        "power_demand_factor": {"table": "7.8", "rows": power},
        "catering_demand_factor": {
            "table": "7.9",
            # Header cells «От 60 до 100» and «Св. 120» are ranges; the lower bound is used as x.
            "x": [2, 3, 5, 8, 10, 15, 20, 30, 60, 120],
            "x_labels": t79[0][1:],
            "y": [num(c) for c in t79[1][1:]],
        },
        "dishwasher_demand_factor": {"table": "7.10", "machines": [1, 2, 3],
                                     "cold_water": [num(c.split("-")[0]) for c in t710[1][1:]],
                                     "hot_water": [num(c.split("-")[-1]) for c in t710[1][1:]]},
        "lighting_power_mismatch": {"table": "7.11", "ratio_ranges_percent": ["20-75", "75-140", "140-250"],
                                    "rows": mismatch},
        "power_factor": {"table": "7.12", "rows": pf},
        "specific_loads": {"table": "7.14", "rows": specific},
    }


def min_sections(t):
    t153 = t["Таблица 15.3"]
    rows = [{"line": r[0], "copper_mm2": num(r[1]), "aluminium_alloy_8030_8176_mm2": num(r[2])}
            for r in t153[2:] if len(r) >= 3]
    return {
        "dataset": "min_cross_sections",
        "dataset_version": DATASET_VERSION,
        "description": "Наименьшие сечения жил (СП 256) и сопутствующие правила по материалу жил.",
        "source": {"documents": [DOCUMENT], "tables": ["15.3"], "clauses": ["15.46", "10.2", "15.3"]},
        "table_15_3": rows,
        "electric_stove_line": {"clause": "10.2", "copper_mm2": 6.0, "aluminium_alloy_8030_8176_mm2": 10.0},
        "aluminium_rules": {
            "clause": "15.3",
            "text": "Допускается применение в питающих и распределительных сетях кабелей с алюминиевыми жилами сечением "
                    "не менее 16 мм². Питание отдельных электроприёмников инженерного оборудования (насосы, "
                    "вентиляторы, калориферы, кондиционеры и т.п.), кроме противопожарного, допускается выполнять "
                    "кабелями с алюминиевыми жилами сечением не менее 2,5 мм².",
            "feeder_min_mm2": 16.0,
            "engineering_equipment_min_mm2": 2.5,
        },
    }


def main():
    src, out = sys.argv[1], sys.argv[2]
    t = tables_by_caption(src)
    datasets = {
        "sp256_residential_loads.json": residential(t),
        "sp256_public_loads.json": public(t),
        "min_cross_sections.json": min_sections(t),
    }
    for name, data in datasets.items():
        with open(os.path.join(out, name), "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=1)
            f.write("\n")


if __name__ == "__main__":
    main()
