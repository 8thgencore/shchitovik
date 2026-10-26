"""Генератор каталога модульных аппаратов защиты (автоматы, УЗО, дифавтоматы).

Каталог собран самостоятельно. Каждая серия описана здесь один раз; модели получаются перебором параметров.
Цены – розничные ориентиры в рублях: для опорных моделей (anchor) они откалиброваны по листингам розницы
(basis=retail_listing), для остальных вычислены масштабированием (derived_from_listing) или оценены (estimate).
Это НЕ прайс-лист: перед использованием в реальных расчётах цены надо обновить (см. catalog/README.md).

Перенесён из учебного проекта (reference/learning-project, собственный каталог автора).
Пишет engine/estimate_core/data/apparatus_catalog.json: модели и производители в одном наборе данных.

Запуск:  python3 -I tools/catalog/build_apparatus_catalog.py
"""
import json
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE.parent.parent / "engine" / "estimate_core" / "data" / "apparatus_catalog.json"
AS_OF = "2026-10"                      # когда снимались ориентиры
MCB_RATINGS = [6, 10, 16, 20, 25, 32, 40, 50, 63]
RCBO_RATINGS = [6, 10, 16, 20, 25, 32, 40]
CUR_F = {6: 0.95, 10: 0.97, 16: 1.0, 20: 1.03, 25: 1.08, 32: 1.15, 40: 1.45, 50: 1.65, 63: 1.9, 80: 2.4, 100: 3.0}
POLE_F = {1: 1.0, 2: 2.05, 3: 3.1, 4: 4.15}
CURVE_F = {"B": 1.0, "C": 1.0, "D": 1.12}
RCD_CUR_F = {16: 0.85, 25: 0.92, 32: 1.0, 40: 1.1, 63: 1.5, 80: 2.0, 100: 2.6}
RCD_TYPE_F = {"AC": 1.0, "A": 1.35}
RCD_MA_F = {10: 1.1, 30: 1.0, 100: 1.05, 300: 1.15}
RCBO_TYPE_F = {"AC": 1.0, "A": 1.3}
RCBO_MA_F = {10: 1.05, 30: 1.0}


def rng(typ, lo=0.75, hi=1.4):
    return dict(min=typ * lo, typ=typ, max=typ * hi)


# Опорная цена: либо rng(оценка), либо (min, typ, max) по наблюдению; calibrated=True для наблюдений.
# ---- MCB ----  anchor = 1P, характеристика C, 16 А
MCB_SERIES = [
    dict(m="iek", s="ВА47-29", ka=4500, curves="BCD", anchor=rng(150)),
    dict(m="iek", s="ВА47-60", ka=6000, curves="BC", anchor=rng(240)),
    dict(m="ekf", s="Basic ВА 47-63", ka=4500, curves="BC", anchor=dict(min=121, typ=145, max=200), calibrated=True),
    dict(m="ekf", s="PROxima ВА 47-63", ka=4500, curves="BCD", anchor=rng(200)),
    dict(m="tdm", s="ВА47-63 SQ", ka=4500, curves="BC", anchor=rng(125)),
    dict(m="dekraft", s="ВА-103", ka=6000, curves="BC", anchor=rng(330)),
    dict(m="chint", s="NXB-63", ka=6000, curves="BCD", anchor=rng(320)),
    dict(m="legrand", s="DX3 6000", ka=6000, curves="BC", anchor=rng(700)),
    dict(m="legrand", s="DX3 10000", ka=10000, curves="BC", anchor=dict(min=2342, typ=2600, max=3300), calibrated=True,
         article={("C", 1, 16): "409114"}),
    dict(m="hager", s="MCN", ka=6000, curves="BCD", anchor=rng(950)),
    dict(m="abb", s="S200", ka=6000, curves="BCD", anchor=rng(1000)),
    dict(m="schneider", s="Easy9", ka=4500, curves="BC", anchor=rng(430)),
    dict(m="schneider", s="Acti9 iC60N", ka=6000, curves="BCD", anchor=dict(min=584, typ=680, max=900), calibrated=True,
         article={("C", 1, 16): "A9F79116"}),
    dict(m="schneider", s="Acti9 iK60N", ka=6000, curves="BC", anchor=rng(520)),
    dict(m="siemens", s="5SL6", ka=6000, curves="BC", anchor=rng(850)),
]

# ---- RCD (УЗО) ----  anchor = 2P, ток утечки 30 мА, тип/номинал из anchor_spec
RCD_SERIES = [
    dict(m="iek", s="ВД1-63", types=["AC", "A"], ratings=[16, 25, 40, 63, 80], anchor_spec=("AC", 25),
         anchor=dict(min=1110, typ=1300, max=1700), calibrated=True, article={("AC", 2, 25, 30): "MDV10-2-025-030"}),
    dict(m="iek", s="KARAT ВД3-63", types=["A"], ratings=[25, 40, 63], anchor_spec=("A", 40),
         anchor=dict(min=2295, typ=2500, max=3100), calibrated=True, article={("A", 2, 40, 30): "MDV21-2-040-030"}),
    dict(m="ekf", s="PROxima ВД-63", types=["AC", "A"], ratings=[25, 40, 63], anchor_spec=("AC", 25), anchor=rng(1000)),
    dict(m="dekraft", s="ВД-102", types=["AC", "A"], ratings=[25, 40, 63], anchor_spec=("AC", 25), anchor=rng(1450)),
    dict(m="chint", s="NL1-63", types=["AC", "A"], ratings=[25, 40, 63], anchor_spec=("AC", 40),
         anchor=dict(min=1855, typ=2050, max=2400), calibrated=True),
    dict(m="legrand", s="RX3 (ВДТ)", types=["AC", "A"], ratings=[25, 40, 63], anchor_spec=("AC", 40),
         anchor=dict(min=2565, typ=2700, max=3100), calibrated=True, article={("AC", 2, 40, 30): "402025"}),
    dict(m="legrand", s="DX3 (УЗО)", types=["A"], ratings=[25, 40, 63, 80], anchor_spec=("A", 40), anchor=rng(4500)),
    dict(m="hager", s="CDA", types=["AC", "A"], ratings=[25, 40, 63], anchor_spec=("AC", 25), anchor=rng(4800)),
    dict(m="abb", s="F200", types=["AC", "A"], ratings=[25, 40, 63], anchor_spec=("AC", 25),
         anchor=dict(min=4152, typ=4900, max=5800), calibrated=True, article={("AC", 2, 25, 30): "2CSF202001R1250"}, selective=True),
    dict(m="schneider", s="Easy9 (УЗО)", types=["AC", "A"], ratings=[25, 40, 63], anchor_spec=("AC", 25), anchor=rng(2000)),
    dict(m="schneider", s="Acti9 iID", types=["AC", "A"], ratings=[25, 40, 63], anchor_spec=("AC", 25), anchor=rng(4000)),
    dict(m="siemens", s="5SM3", types=["AC", "A"], ratings=[25, 40, 63], anchor_spec=("AC", 25), anchor=rng(4500)),
]

# ---- RCBO (дифавтоматы 1P+N) ----  anchor = C16, 30 мА, тип из anchor_type
# mu – ширина в модулях 17,5 мм (по умолчанию 2); ratings/curves – если серия уже общего ряда.
RCBO_SERIES = [
    dict(m="iek", s="АВДТ34", ka=4500, types=["AC", "A"], mas=[10, 30], anchor_type="AC", anchor=rng(1500)),
    dict(m="ekf", s="PROxima АВДТ-63", ka=4500, types=["AC", "A"], mas=[30], anchor_type="AC", anchor=rng(1350)),
    dict(m="dekraft", s="ДИФ-103", ka=6000, types=["AC", "A"], mas=[30], anchor_type="AC", anchor=rng(2200)),
    dict(m="chint", s="NXBLE-32", ka=6000, types=["AC", "A"], mas=[30], anchor_type="AC", anchor=rng(1900)),
    dict(m="legrand", s="RX3 (дифавтомат)", ka=6000, types=["AC", "A"], mas=[10, 30], anchor_type="AC", anchor=rng(3500),
         article={("AC", "C", 16, 30): "419399"}),
    dict(m="abb", s="DS201", ka=6000, types=["AC", "A"], mas=[10, 30], anchor_type="AC", anchor=rng(6500)),
    dict(m="schneider", s="Easy9 (дифавтомат)", ka=4500, types=["AC", "A"], mas=[30], anchor_type="AC", anchor=rng(3300)),
    dict(m="schneider", s="Acti9 iDPN N Vigi", ka=6000, types=["AC", "A"], mas=[10, 30], anchor_type="AC", anchor=rng(4800)),
    dict(m="siemens", s="5SU1", ka=6000, types=["AC", "A"], mas=[30], anchor_type="AC", anchor=rng(5500)),
    # Компактные 1P+N шириной 18 мм (1 модуль). Опорные цены – розничные листинги 2026-10:
    # ЭТМ, Электродус, LEDPremium, IKrussia (AR-B06S-1N-C16C030); Минимакс, Ледгудс, Профсектор
    # (2CSR255150R1164).
    dict(m="iek", s="ARMAT B06S", ka=6000, types=["AC", "A"], mas=[30], anchor_type="AC",
         anchor=dict(min=4010, typ=5010, max=5830), calibrated=True, mu=1, ratings=[6, 10, 16, 20, 25, 32],
         article={("AC", "C", 16, 30): "AR-B06S-1N-C16C030", ("A", "C", 16, 30): "AR-B06S-1N-C16A030",
                  ("A", "B", 16, 30): "AR-B06S-1N-B16A030", ("AC", "C", 25, 30): "AR-B06S-1N-C25C030",
                  ("A", "C", 32, 30): "AR-B06S-1N-C32A030"}),
    dict(m="abb", s="DSN201", ka=6000, types=["AC", "A"], mas=[30], anchor_type="A",
         anchor=dict(min=4590, typ=5840, max=8710), calibrated=True, mu=1, curves="C", ratings=[6, 10, 16, 20, 25, 32],
         article={("A", "C", 16, 30): "2CSR255150R1164", ("AC", "C", 16, 30): "2CSR255050R1164"}),
]


def nice(x):
    step = 5 if x < 1000 else 10
    return int(round(x / step) * step)


def price(anchor, factor, is_anchor, calibrated):
    p = {k: nice(anchor[k] * factor) for k in ("min", "typ", "max")}
    p["min"], p["max"] = min(p["min"], p["typ"]), max(p["max"], p["typ"])
    basis = ("retail_listing" if is_anchor else "derived_from_listing") if calibrated else "estimate"
    return dict(currency="RUB", min=p["min"], typical=p["typ"], max=p["max"], as_of=AS_OF, basis=basis)


_TR = dict(zip("абвгдежзийклмнопрстуфхцчшщъыьэюя",
               ["a", "b", "v", "g", "d", "e", "zh", "z", "i", "y", "k", "l", "m", "n", "o", "p", "r", "s", "t", "u", "f",
                "h", "c", "ch", "sh", "sch", "", "y", "", "e", "yu", "ya"]))


def slug(*parts):
    """Идентификатор из латиницы, цифр и дефисов (кириллица транслитерируется)."""
    out = "".join(_TR.get(ch, ch) for ch in "-".join(str(p) for p in parts).lower())
    out = "".join(ch if ch.isalnum() else "-" for ch in out)
    while "--" in out:
        out = out.replace("--", "-")
    return out.strip("-")


def build():
    products = []
    for s in MCB_SERIES:
        cal = s.get("calibrated", False)
        for curve in s["curves"]:
            for poles in (1, 2, 3, 4):
                for i in MCB_RATINGS:
                    f = POLE_F[poles] * CURVE_F[curve] * CUR_F[i] / (CURVE_F["C"] * CUR_F[16])
                    is_anchor = (curve, poles, i) == ("C", 1, 16)
                    products.append(dict(
                        id=slug(s["m"], s["s"], f"{poles}p", f"{curve}{i}"), manufacturer=s["m"], series=s["s"],
                        function="MCB", article=(s.get("article") or {}).get((curve, poles, i)),
                        spec=dict(poles=poles, rated_current_a=i, curve=curve, breaking_capacity_a=s["ka"], selectivity="NONE"),
                        module_units=poles, price=price(s["anchor"], f, is_anchor, cal), status="ACTIVE"))
    for s in RCD_SERIES:
        cal = s.get("calibrated", False)
        a_type, a_cur = s["anchor_spec"]
        for t in s["types"]:
            for poles in (2, 4):
                for i in s["ratings"]:
                    for ma in (30, 100, 300):
                        if ma == 100 and i < 40: continue
                        if ma == 300 and poles == 2 and i > 40: continue
                        f = (RCD_CUR_F[i] / RCD_CUR_F[a_cur]) * (1.9 if poles == 4 else 1.0) * (RCD_TYPE_F[t] / RCD_TYPE_F[a_type]) * RCD_MA_F[ma]
                        is_anchor = (t, poles, i, ma) == (a_type, 2, a_cur, 30)
                        products.append(dict(
                            id=slug(s["m"], s["s"], f"{poles}p", f"{i}a", f"{ma}ma", t), manufacturer=s["m"], series=s["s"],
                            function="RCD", article=(s.get("article") or {}).get((t, poles, i, ma)),
                            spec=dict(poles=poles, rated_current_a=i, leakage_ma=ma, rcd_type=t, selectivity="NONE"),
                            module_units=poles, price=price(s["anchor"], f, is_anchor, cal), status="ACTIVE"))
        if s.get("selective"):                     # селективные (S) на 300 мА, 4P
            for i in (40, 63):
                f = (RCD_CUR_F[i] / RCD_CUR_F[a_cur]) * 1.9 * 1.35 * RCD_MA_F[300] * 1.5
                products.append(dict(
                    id=slug(s["m"], s["s"], "4p", f"{i}a", "300ma", "a-s"), manufacturer=s["m"], series=s["s"],
                    function="RCD", article=None,
                    spec=dict(poles=4, rated_current_a=i, leakage_ma=300, rcd_type="A", selectivity="S"),
                    module_units=4, price=price(s["anchor"], f, False, s.get("calibrated", False)), status="ACTIVE"))
    for s in RCBO_SERIES:
        cal = s.get("calibrated", False)
        for t in s["types"]:
            for curve in s.get("curves", "BC"):
                for ma in s["mas"]:
                    for i in s.get("ratings", RCBO_RATINGS):
                        f = (CUR_F[i] / CUR_F[16]) * (RCBO_TYPE_F[t] / RCBO_TYPE_F[s["anchor_type"]]) * RCBO_MA_F[ma] * CURVE_F[curve]
                        is_anchor = (t, curve, i, ma) == (s["anchor_type"], "C", 16, 30)
                        products.append(dict(
                            id=slug(s["m"], s["s"], "1pn", f"{curve}{i}", f"{ma}ma", t), manufacturer=s["m"], series=s["s"],
                            function="RCBO", article=(s.get("article") or {}).get((t, curve, i, ma)),
                            spec=dict(poles=2, rated_current_a=i, curve=curve, breaking_capacity_a=s["ka"], leakage_ma=ma,
                                      rcd_type=t, selectivity="NONE"),
                            module_units=s.get("mu", 2), price=price(s["anchor"], f, is_anchor, cal), status="ACTIVE"))
    return products


def main():
    products = build()
    ids = [p["id"] for p in products]
    assert len(ids) == len(set(ids)), "дубликаты id: " + str([i for i in ids if ids.count(i) > 1][:5])
    manufacturers = json.loads((HERE / "manufacturers.json").read_text(encoding="utf-8"))
    out = dict(
        dataset="apparatus_catalog",
        dataset_version=f"{AS_OF}-2",
        catalog_version=f"{AS_OF}-2",
        currency="RUB",
        price_as_of=AS_OF,
        price_disclaimer="Ориентировочные розничные цены, не прайс-лист. basis: retail_listing – откалибровано по розничному "
                         "листингу; derived_from_listing – масштабирование от такой модели; estimate – экспертная оценка.",
        tiers=manufacturers["_meta"]["tiers"],
        manufacturers=manufacturers["manufacturers"],
        products=products,
    )
    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"products: {len(products)}")


if __name__ == "__main__":
    main()
