"""Builds cable_catalog.json, auxiliary_devices.json and fallback_prices.json for estimate_core.

All prices are estimates (basis=estimate) of Russian retail, rubles, as of AS_OF; they are an
order-of-magnitude reference for the estimate range, not a price list. Update the anchors below
and rerun when calibrating against real listings.

Usage: python3 -I tools/catalog/build_price_catalogs.py
"""
import json
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE.parent.parent / "engine" / "estimate_core" / "data"
AS_OF = "2026-10"
VERSION = f"{AS_OF}-1"

# ---------------------------------------------------------------- cables
# typical ₽/m ≈ (cores · S · k_material + base) · k_mark; range: min = 0.85·typ, max = 1.3·typ.
# k_material reflects conductor metal cost per mm²·m (copper ≈ 13 ₽, aluminium ≈ 2.2 ₽).
CABLE_MARKS = [
    dict(id="vvgng_a_ls", name="ВВГнг(А)-LS", material="copper", k=1.0,
         note="Самый распространённый кабель для групповых сетей; нераспространение горения, низкое дымовыделение."),
    dict(id="vvgng_a_frls", name="ВВГнг(А)-FRLS", material="copper", k=1.35,
         note="Огнестойкий; для систем противопожарной защиты."),
    dict(id="nym", name="NYM", material="copper", k=1.15, note="Кабель с мягкой оболочкой, удобен в монтаже."),
    dict(id="ppgng_a_hf", name="ППГнг(А)-HF", material="copper", k=1.3, note="Безгалогенный; для общественных зданий."),
    dict(id="avvgng_a_ls", name="АВВГнг(А)-LS", material="aluminium", k=1.0,
         note="Алюминиевые жилы; в групповых сетях допускаются только сплавы 8030/8176 (СП 256, табл. 15.3)."),
]
COPPER_SECTIONS = [1.5, 2.5, 4, 6, 10, 16, 25, 35]
ALUMINIUM_SECTIONS = [2.5, 4, 6, 10, 16, 25, 35, 50, 70, 95, 120]
K_MATERIAL = {"copper": 13.0, "aluminium": 2.2}
BASE = {"copper": 15.0, "aluminium": 20.0}


def rub(x):
    step = 1 if x < 100 else 5
    return int(round(x / step) * step)


def cable_catalog():
    items = []
    for mark in CABLE_MARKS:
        sections = COPPER_SECTIONS if mark["material"] == "copper" else ALUMINIUM_SECTIONS
        for cores in (3, 5):
            for s in sections:
                typ = (cores * s * K_MATERIAL[mark["material"]] + BASE[mark["material"]]) * mark["k"]
                items.append(dict(
                    id=f'{mark["id"]}-{cores}x{str(s).replace(".", "_")}',
                    mark=mark["id"], cores=cores, section_mm2=s,
                    price_per_m=dict(currency="RUB", min=rub(typ * 0.85), typical=rub(typ), max=rub(typ * 1.3),
                                     as_of=AS_OF, basis="estimate"),
                ))
    return dict(
        dataset="cable_catalog", dataset_version=VERSION,
        description="Кабели для групповых и питающих линий; цена за метр.",
        price_disclaimer="Оценка розничной цены: (жилы·S·k_мат + база)·k_марки; не прайс-лист.",
        marks=[{k: v for k, v in m.items() if k != "k"} for m in CABLE_MARKS],
        items=items,
    )


# ---------------------------------------------------------------- auxiliary devices
TIERS = {"budget": 1.0, "mid": 1.6, "premium": 3.0}


def price(typ):
    return dict(currency="RUB", min=rub(typ * 0.8), typical=rub(typ), max=rub(typ * 1.4), as_of=AS_OF, basis="estimate")


def auxiliary_devices():
    base = [
        # kind, poles, rated A, description, budget typical ₽, module units
        ("voltage_relay", 2, 40, "Реле напряжения однофазное 40 А", 1600, 2),
        ("voltage_relay", 2, 63, "Реле напряжения однофазное 63 А", 2000, 2),
        ("voltage_relay", 4, 63, "Реле контроля фаз (трёхфазное) с контактором до 63 А", 6500, 6),
        ("spd", 2, None, "УЗИП тип 2, 1P+N", 2500, 2),
        ("spd", 4, None, "УЗИП тип 2, 3P+N", 5000, 4),
        ("spd_type1", 2, None, "УЗИП тип 1+2, 1P+N (воздушный ввод)", 7000, 4),
        ("spd_type1", 4, None, "УЗИП тип 1+2, 3P+N (воздушный ввод)", 14000, 8),
    ]
    items = []
    for kind, poles, rated, name, typ, modules in base:
        for tier, k in TIERS.items():
            items.append(dict(
                id=f"{kind}-{poles}p{'-' + str(rated) if rated else ''}-{tier}",
                kind=kind, poles=poles, rated_current_a=rated, tier=tier, name=name, module_units=modules,
                price=price(typ * k),
            ))
    return dict(
        dataset="auxiliary_devices", dataset_version=VERSION,
        description="Вспомогательные устройства щита: реле напряжения, реле контроля фаз, УЗИП.",
        price_disclaimer="Оценка по сегментам (budget/mid/premium); не прайс-лист.",
        notes=[
            "Реле напряжения – защита приёмников от перенапряжения при обрыве нуля (рекомендация, не требование норм).",
            "УЗИП – ГОСТ Р 50571.4.44 / ГОСТ Р 50571.5.53 (534); тип 1+2 – при воздушном вводе.",
        ],
        items=items,
    )


# ---------------------------------------------------------------- fallback prices
def fallback_prices():
    """Average prices by function/poles/rating range where the catalog has no compatible model."""
    rows = [
        # function, poles, min A, max A, extra, budget typical ₽, module units
        ("MCB", 1, 80, 125, {}, 1300, 1),
        ("MCB", 2, 80, 125, {}, 2700, 2),
        ("MCB", 3, 80, 125, {}, 4000, 3),
        ("MCB", 4, 80, 125, {}, 5300, 4),
        ("RCBO", 2, 6, 63, {}, 1700, 2),
        ("RCBO", 4, 6, 40, {}, 6500, 4),
        ("RCD", 2, 16, 63, {}, 1500, 2),
        ("RCD", 4, 16, 100, {}, 3500, 4),
        ("RCD", 2, 25, 100, {"selectivity": "S"}, 5500, 2),
        ("RCD", 4, 25, 100, {"selectivity": "S"}, 9000, 4),
        ("MCB", 1, 6, 63, {}, 200, 1),
        ("MCB", 2, 6, 63, {}, 450, 2),
        ("MCB", 3, 6, 63, {}, 700, 3),
        ("MCB", 4, 6, 63, {}, 950, 4),
    ]
    items = []
    for function, poles, lo, hi, extra, typ, modules in rows:
        for tier, k in TIERS.items():
            items.append(dict(function=function, poles=poles, min_rated_a=lo, max_rated_a=hi, tier=tier,
                              module_units=modules, price=price(typ * k), **extra))
    return dict(
        dataset="fallback_prices", dataset_version=VERSION,
        description="Усреднённые цены аппаратов по диапазонам номиналов – когда в каталоге нет совместимой модели.",
        price_disclaimer="Оценка по сегментам; не прайс-лист.",
        items=items,
    )


def main():
    for name, data in (("cable_catalog.json", cable_catalog()), ("auxiliary_devices.json", auxiliary_devices()),
                       ("fallback_prices.json", fallback_prices())):
        (OUT / name).write_text(json.dumps(data, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
        print(name, len(data["items"]))


if __name__ == "__main__":
    main()
