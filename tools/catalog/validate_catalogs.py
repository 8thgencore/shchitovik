"""Integrity checks of engine/estimate_core/data/*.json. Exit code 1 on errors.

Usage: python3 -I tools/catalog/validate_catalogs.py
"""
import json
import pathlib
import sys

DATA = pathlib.Path(__file__).resolve().parent.parent.parent / "engine" / "estimate_core" / "data"
errors = []


def load(name):
    return json.loads((DATA / name).read_text(encoding="utf-8"))


def check_price(where, p):
    if not 0 < p["min"] <= p["typical"] <= p["max"]:
        errors.append(f"{where}: нарушено 0 < min ≤ typical ≤ max: {p}")
    if p["basis"] not in ("retail_listing", "derived_from_listing", "estimate"):
        errors.append(f"{where}: неизвестный basis {p['basis']}")


app = load("apparatus_catalog.json")
mf = {m["id"]: m for m in app["manufacturers"]}
seen = set()
for p in app["products"]:
    pid = p["id"]
    if pid in seen:
        errors.append(f"{pid}: дубликат id")
    seen.add(pid)
    if p["manufacturer"] not in mf:
        errors.append(f"{pid}: неизвестный производитель {p['manufacturer']}")
    elif p["function"] not in mf[p["manufacturer"]]["segments"]:
        errors.append(f"{pid}: {p['function']} вне сегментов производителя")
    if mf.get(p["manufacturer"], {}).get("tier") not in app["tiers"]:
        errors.append(f"{pid}: сегмент производителя не описан")
    s = p["spec"]
    check_price(pid, p["price"])
    if p["function"] in ("MCB", "RCBO") and s["curve"] not in "BCD":
        errors.append(f"{pid}: кривая {s['curve']}")
    if p["function"] in ("RCD", "RCBO") and s["rcd_type"] not in ("AC", "A", "F", "B"):
        errors.append(f"{pid}: тип УЗО")
    if p["function"] in ("RCD", "RCBO") and s["poles"] not in (2, 4):
        errors.append(f"{pid}: полюса УЗО/дифавтомата")
    if p["function"] == "MCB" and not 1 <= s["poles"] <= 4:
        errors.append(f"{pid}: полюса")
    if p["module_units"] < 1:
        errors.append(f"{pid}: модули")
for m, v in mf.items():
    for seg in v["segments"]:
        if not any(p["manufacturer"] == m and p["function"] == seg for p in app["products"]):
            errors.append(f"{m}: заявлен сегмент {seg}, моделей нет")

cables = load("cable_catalog.json")
marks = {m["id"] for m in cables["marks"]}
for c in cables["items"]:
    if c["mark"] not in marks:
        errors.append(f"{c['id']}: неизвестная марка")
    check_price(c["id"], c["price_per_m"])

for item in load("auxiliary_devices.json")["items"]:
    check_price(item["id"], item["price"])
for i, item in enumerate(load("fallback_prices.json")["items"]):
    check_price(f"fallback[{i}]", item["price"])
    if item["min_rated_a"] > item["max_rated_a"]:
        errors.append(f"fallback[{i}]: диапазон номиналов")

# Coverage of typical requirements by every price segment (report, not an error: gaps are
# priced by fallback_prices.json).
TYPE_ORDER = ["AC", "A", "F", "B"]


def covers(p, function, poles, rated, curve=None, leakage=None, rcd_type=None, selective=False):
    s = p["spec"]
    if p["function"] != function or s["poles"] != poles or p["status"] != "ACTIVE":
        return False
    if function == "RCD":
        if s["rated_current_a"] < rated:
            return False
    elif s["rated_current_a"] != rated or s.get("curve") != curve:
        return False
    if leakage is not None and s.get("leakage_ma") != leakage:
        return False
    if rcd_type is not None and TYPE_ORDER.index(s.get("rcd_type", "AC")) < TYPE_ORDER.index(rcd_type):
        return False
    return function == "MCB" or (s.get("selectivity") == "S") == selective


TYPICAL = (
    [("MCB", 1, i, dict(curve="C")) for i in (10, 16, 20, 25, 32, 40, 50, 63)]
    + [("MCB", 1, i, dict(curve="B")) for i in (10, 16, 20)]
    + [("MCB", 2, i, dict(curve="C")) for i in (25, 32, 40, 50, 63)]
    + [("MCB", 3, i, dict(curve="C")) for i in (16, 25, 32, 40, 50, 63)]
    + [("RCBO", 2, i, dict(curve="C", leakage=30, rcd_type="A")) for i in (10, 16, 20, 25, 32)]
    + [("RCD", 2, i, dict(leakage=30, rcd_type="A")) for i in (25, 40, 63)]
    + [("RCD", 4, i, dict(leakage=30, rcd_type="A")) for i in (25, 40, 63)]
    + [("RCD", 2, 40, dict(leakage=300, rcd_type="A", selective=True)),
       ("RCD", 4, 40, dict(leakage=300, rcd_type="A", selective=True))]
)
coverage = []
for tier in app["tiers"]:
    products = [p for p in app["products"] if mf[p["manufacturer"]]["tier"] == tier]
    missing = [f"{f} {poles}P {kw.get('curve', '')}{rated} {kw.get('leakage', '')}{'S' if kw.get('selective') else ''}".strip()
               for f, poles, rated, kw in TYPICAL if not any(covers(p, f, poles, rated, **kw) for p in products)]
    coverage.append(f"{tier}: не покрыто {len(missing)} из {len(TYPICAL)} типовых требований"
                    + (f" — {', '.join(missing)}" if missing else ""))

print(f"моделей: {len(app['products'])}, кабелей: {len(cables['items'])}, ошибок: {len(errors)}")
for line in coverage:
    print(" *", line)
for e in errors[:30]:
    print(" -", e)
sys.exit(1 if errors else 0)
