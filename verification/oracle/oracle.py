"""Independent re-implementation of the «Щитовик» calculation rules for cross-checking.

Written from the norms and the product rules listed in verification/VERIFICATION.md (F1–F22),
not translated from the Dart code. It reads the normative tables from
engine/norms_data/data/*.json; the transcription of those tables is verified separately (T1–T15).

Standard library only. Run vectors with: python3 -I verification/oracle/run_vectors.py
"""
import json
import math
import pathlib

DATA = pathlib.Path(__file__).resolve().parents[2] / "engine" / "norms_data" / "data"
EPS = 1e-9


def _load(name):
    return json.loads((DATA / f"{name}.json").read_text(encoding="utf-8"))


AMPACITY = _load("ampacity")
TEMPERATURE = _load("temperature_factors")
SOIL = _load("soil_resistivity_factors")
GROUPING = _load("grouping_factors")
METHODS = {m["id"]: m for m in _load("installation_methods")["methods"]}
CONDUCTORS = _load("conductors")
BREAKERS = _load("breakers")
VD = _load("voltage_drop_limits")
MIN_SECTIONS = _load("min_cross_sections")
CONSTANTS = _load("electrical_constants")
RESIDENTIAL = _load("sp256_residential_loads")
PUBLIC = _load("sp256_public_loads")

SECTIONS = CONSTANTS["standard_sections_mm2"]
RATINGS = BREAKERS["rated_currents_a"]
COOKING = {"electric_stove", "cooktop"}

# ------------------------------------------------------------------ tables


def first_step_at_or_above(steps, x):
    for i, s in enumerate(steps):
        if s >= x:
            return i
    return None


def interpolate(xs, ys, x):
    pts = [(a, b) for a, b in zip(xs, ys) if b is not None]
    if x <= pts[0][0]:
        return pts[0][1]
    if x >= pts[-1][0]:
        return pts[-1][1]
    for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
        if x <= x1:
            return y0 + (y1 - y0) * (x - x0) / (x1 - x0)
    return pts[-1][1]


def tabulated_current(insulation, material, loaded, method, section):
    for c in AMPACITY["columns"]:
        if (c["insulation"], c["material"], c["loaded_conductors"], c["method"]) == (insulation, material, loaded, method):
            i = AMPACITY["sections_mm2"].index(section) if section in AMPACITY["sections_mm2"] else None
            return None if i is None else c["values_a"][i]
    return None


def temperature_factor(environment, insulation, t):
    table = TEMPERATURE[environment]
    i = first_step_at_or_above(table["steps_c"], t)
    return None if i is None else table[insulation][i]


def soil_factor(method, rho):
    i = first_step_at_or_above(SOIL["resistivity_k_m_per_w"], rho)
    if i is None:
        return None
    return (SOIL["in_duct"] if method == "D1" else SOIL["direct_in_ground"])[i]


def grouping_factor(grouping_key, n):
    if grouping_key in ("direct_in_ground", "in_ducts_multicore"):
        if n <= 1:
            return 1.0
        table = GROUPING["direct_in_ground" if grouping_key == "direct_in_ground" else "in_ducts_multicore"]
        i = first_step_at_or_above(table["counts"], n)
        return None if i is None else table["factors"][i][0]  # cables touching
    air = GROUPING["air"]
    rows = {r["arrangement"]: r["factors"] for r in air["arrangements"]}

    def row(key):
        if n <= 1 and key != "single_layer_under_ceiling":
            return 1.0
        i = first_step_at_or_above(air["counts"], n)
        return None if i is None else rows[key][i]

    value = row(grouping_key)
    return value if value is not None else row("bunched")


# ------------------------------------------------------------------ currents


def device_vector(d, u0, ul, demand=False):
    p = d["power_w"] * d.get("quantity", 1) * (d.get("usage_factor", 1) if demand else 1)
    active = p / (math.sqrt(3) * ul) if d.get("phases", 1) == 3 else p / u0
    cos = d.get("cos_phi", 1)
    reactive = 0.0 if cos >= 1 else active * math.sqrt(1 - cos * cos) / cos
    return active, reactive


def magnitude(v):
    return math.hypot(v[0], v[1])


def add(a, b):
    return a[0] + b[0], a[1] + b[1]


# ------------------------------------------------------------------ circuits


def is_lighting_load(d):
    return d["kind"] == "lighting" or (d["kind"] == "ventilation" and d.get("connection") == "fixed" and d["power_w"] <= 100)


def build_circuits(devices, rooms, u0, ul):
    rooms_by_id = {r["id"]: r for r in rooms}
    order = {r["id"]: i for i, r in enumerate(rooms)}
    current = {d["id"]: magnitude(device_vector(d, u0, ul)) for d in devices}
    dedicated, shared, meta = [], {}, {}
    for d in devices:
        room = rooms_by_id[d["room_id"]]
        purpose = "lighting" if is_lighting_load(d) else "power"
        limit = 10.0 if purpose == "lighting" else 16.0
        if d.get("dedicated_line", "no") != "no" or d.get("phases", 1) == 3 or current[d["id"]] > limit + EPS:
            dedicated.append(dict(id=f"dev-{d['id']}", purpose="dedicated", devices=[d], rooms=[room],
                                  sort=f"3-{order[room['id']]:04d}-{devices.index(d):04d}"))
            continue
        if purpose == "lighting":
            zone = {"bathroom": "wet", "outdoor": "outdoor"}.get(room["kind"], "dry")
            key, sort = f"light-{zone}", f"1-{['dry', 'wet', 'outdoor'].index(zone)}"
        else:
            key, sort = f"power-{room['id']}", f"2-{order[room['id']]:04d}"
        shared.setdefault(key, []).append(d)
        meta[key] = (purpose, 10.0 if purpose == "lighting" else 16.0, sort)
    circuits = list(dedicated)
    for key, items in shared.items():
        purpose, limit, sort = meta[key]
        bins, loads = [], []
        for d in sorted(items, key=lambda d: (-current[d["id"]], d["id"])):
            for i, load in enumerate(loads):
                if load + current[d["id"]] <= limit + EPS:
                    bins[i].append(d)
                    loads[i] += current[d["id"]]
                    break
            else:
                bins.append([d])
                loads.append(current[d["id"]])
        for n, b in enumerate(bins, start=1):
            b = sorted(b, key=devices.index)
            b_rooms = sorted({d["room_id"] for d in b}, key=lambda r: order[r])
            circuits.append(dict(id=f"{key}-{n}", purpose=purpose, devices=b,
                                 rooms=[rooms_by_id[r] for r in b_rooms], sort=f"{sort}-{n:03d}"))
    return sorted(circuits, key=lambda c: c["sort"])


# ------------------------------------------------------------------ protection


MIN_BREAKER = {"lighting": 10.0, "power": 16.0, "dedicated": 10.0}
TRIP = BREAKERS["instantaneous_trip_multiple"]


def rated_at_or_above(x):
    for r in RATINGS:
        if r >= x:
            return float(r)
    return None


def needs_rcd(c):
    devices, rooms = c["devices"], c["rooms"]
    return (any(d.get("connection", "socket") == "socket" for d in devices)
            or any(r["kind"] in ("bathroom", "outdoor") for r in rooms)
            or any(d["kind"] in ("floor_heating", "ev_charger") for d in devices))


def curve_options(start, rated):
    def ok(curve):
        return start < TRIP[curve]["min"] * rated - EPS
    if ok("C"):
        return ["C"] + (["B"] if ok("B") else [])
    return ["D"]


# ------------------------------------------------------------------ cable


def resistance(material, section, insulation):
    r20 = CONDUCTORS["resistance_20c_ohm_per_km"][material][CONDUCTORS["sections_mm2"].index(section)]
    beta = CONDUCTORS["materials"][material]["beta_c"]
    t = CONDUCTORS["max_operating_temperature_c"][insulation]
    return r20 * (1 + (t - 20) / (beta + 20))


def pe_section(s):
    raw = s if s <= 16 else (16 if s <= 35 else s / 2)
    return next(x for x in SECTIONS if x + EPS >= raw)


def vd_limit(lighting, length):
    base = VD["from_building_input"]["lighting_percent" if lighting else "other_percent"]
    long = VD["long_line_allowance"]
    if length <= long["length_threshold_m"]:
        return base
    return base + min((length - long["length_threshold_m"]) * long["percent_per_m"], long["max_extra_percent"])


def vd_percent(phases, material, section, length, ib, cos, u0):
    f = VD["formula_g"]
    b = f["b_three_phase"] if phases == 3 else f["b_single_phase"]
    sin = math.sqrt(max(0.0, 1 - cos * cos))
    u = b * (f["rho1_ohm_mm2_per_m"][material] * length / section * cos + f["lambda_mohm_per_m"] / 1000 * length * sin) * ib
    return 100 * u / u0


def evaluate_cable(spec, section, curve):
    method = METHODS[spec["method"]]
    ref = method["reference_method"]
    loaded = 3 if spec["phases"] == 3 else 2
    itab = tabulated_current(spec["insulation"], spec["material"], loaded, ref, section)
    kt = temperature_factor(method["environment"], spec["insulation"], spec["ambient"])
    kg = grouping_factor(method["grouping"], spec["grouped"])
    ks = soil_factor(ref, spec["soil"]) if ref in ("D1", "D2") else 1.0
    covered = None not in (itab, kt, kg, ks)
    iz = itab * kt * kg * ks if covered else None
    checks = {"datasetCoverage": "passed" if covered else "failed"}
    checks["breakerVsAmpacity"] = "notEvaluated" if iz is None else ("passed" if spec["in"] <= iz + EPS else "failed")
    checks["minimumSection"] = "passed" if section + EPS >= spec["min_section"] else "failed"
    length = spec["length"]
    limit = vd_limit(spec["lighting"], length or 0)
    vd = zs = ik = None
    if length is None:
        checks["voltageDrop"] = "notEvaluated"
    else:
        vd = vd_percent(spec["phases"], spec["material"], section, length, spec["ib"], spec["cos"], spec["u0"])
        checks["voltageDrop"] = "passed" if vd <= limit + EPS else "failed"
    checks["protectiveConductor"] = "passed"
    pe = pe_section(section)
    ia = TRIP[curve]["max"] * spec["in"]
    if length is None:
        checks["faultDisconnection"] = "notEvaluated"
    else:
        r = (resistance(spec["material"], section, spec["insulation"]) + resistance(spec["material"], pe, spec["insulation"])) * length / 1000
        x = 2 * CONDUCTORS["reactance_ohm_per_km"]["multicore_cable"] * length / 1000
        zs = spec["zext"] + math.hypot(r, x)
        ik = 0.95 * spec["u0"] / zs
        checks["faultDisconnection"] = "passed" if ik + EPS >= ia else "failed"
    # ГОСТ Р 50571.4.43, 435.1: overload protection with sufficient breaking capacity covers short circuit
    checks["shortCircuitThermal"] = "passed" if checks["breakerVsAmpacity"] == "passed" else "notEvaluated"
    if spec["material"] == "aluminium":
        checks["conductorMaterial"] = "warning"
    return dict(section=section, pe=pe, iz=iz, vd=vd, limit=limit, zs=zs, ik=ik, checks=checks,
                passed=all(v != "failed" for v in checks.values()))


def select_cable(spec, curves):
    fallback = None
    for s in SECTIONS:
        if s + EPS < spec["min_section"]:
            continue
        for curve in curves:
            e = evaluate_cable(spec, s, curve)
            if e["passed"]:
                return e, curve
            if curve == curves[0] and fallback is None and e["checks"]["datasetCoverage"] == "passed" \
                    and e["checks"]["breakerVsAmpacity"] == "passed":
                fallback = (e, curve)
    if fallback:
        return fallback
    method = METHODS[spec["method"]]
    largest = [s for s in SECTIONS if tabulated_current(spec["insulation"], spec["material"],
                                                        3 if spec["phases"] == 3 else 2, method["reference_method"], s)][-1]
    return evaluate_cable(spec, largest, curves[0]), curves[0]


def min_section(c, material):
    al = material == "aluminium"
    if any(d["kind"] in COOKING for d in c["devices"]):
        return 10.0 if al else 6.0
    if c["purpose"] == "lighting":
        return 2.5 if al else 1.5
    if c["purpose"] == "power" or any(d.get("connection", "socket") == "socket" for d in c["devices"]):
        return 4.0 if al else 2.5
    return 2.5 if al else 1.5


# ------------------------------------------------------------------ input demand


def residential_demand(inp, devices, installed):
    has_cooking = any(d["kind"] in COOKING for d in devices)
    fuel = inp.get("cooking_fuel") or ("electric" if has_cooking else "naturalGas")
    row = {"naturalGas": "natural_gas", "liquefiedGasOrSolidFuel": "liquefied_gas_or_solid_fuel",
           "electric": "electric_8_5_kw"}[fuel]
    specific = RESIDENTIAL["specific_load_kw_per_apartment"]["rows"][row][0] * 1000  # column «1–5»
    allowed = (inp.get("supply") or {}).get("allowed_power_kw")
    declared = allowed * 1000 if allowed is not None else installed
    t = RESIDENTIAL["comfort_demand_factor"]
    comfort = declared * interpolate(t["declared_power_kw"], t["kc"], declared / 1000)
    ac = any(d["kind"] == "air_conditioner" for d in devices)
    key = ("apartments_electric_stoves" if fuel == "electric" else "apartments_gas_or_solid_fuel_stoves") + \
          ("_with_air_conditioners" if ac else "")
    return max(comfort, specific), RESIDENTIAL["power_factor"][key]


SANITARY = {"refrigeration", "air_conditioner", "ventilation", "pump"}
THERMAL = {"oven", "electric_stove", "cooktop", "kitchen_appliance", "water_heater"}


def power_kc_table78(item, n):
    row = next(r for r in PUBLIC["power_demand_factor"]["rows"] if r["item"] == item)
    if n <= 1:
        return 1.0
    return interpolate([3, 5], [row["kc_up_to_3"], row["kc_over_5"]], n)


def sanitary_kc(group):
    count = sum(d.get("quantity", 1) for d in group)
    total = sum(d["power_w"] * d.get("quantity", 1) for d in group)
    sanitary = sum(d["power_w"] * d.get("quantity", 1) for d in group if d["kind"] in SANITARY)
    share = 0 if total == 0 else sanitary / total * 100
    index = 0 if share >= 85 else 1 if share >= 75 else 2 if share >= 50 else 3 if share >= 25 else 4
    if count <= 1:
        return 1.0
    t = PUBLIC["sanitary_demand_factor"]
    return interpolate(t["receivers"], t["rows"][index]["kc"], count)


def public_demand(inp, devices):
    profile = inp.get("commercial_profile") or ("workshop" if inp["object_type"] == "garageWorkshop" else "office")
    lighting = [d for d in devices if d["kind"] == "lighting"]
    power = [d for d in devices if d["kind"] != "lighting"]
    p_light = sum(d["power_w"] * d.get("quantity", 1) for d in lighting)
    light_row = 2 if profile in ("catering", "workshop") else 3
    t = PUBLIC["lighting_demand_factor"]
    kc_light = 1.0 if p_light == 0 else interpolate(
        t["installed_kw"], next(r for r in t["rows"] if r["item"] == light_row)["kc"], p_light / 1000)
    total = p_light * kc_light

    def kc_for(group):
        n = sum(d.get("quantity", 1) for d in group)
        if n == 0:
            return 0.0
        if profile == "workshop":
            return power_kc_table78(11, n)
        if profile == "services":
            return power_kc_table78(15, n)
        return sanitary_kc(group)

    def power_of(group):
        return sum(d["power_w"] * d.get("quantity", 1) for d in group)

    if profile == "catering":
        thermal = [d for d in power if d["kind"] in THERMAL]
        other = [d for d in power if d["kind"] not in THERMAL]
        n = sum(d.get("quantity", 1) for d in thermal)
        t9 = PUBLIC["catering_demand_factor"]
        kc_t = 1.0 if n <= 1 else interpolate(t9["x"], t9["y"], n)
        total += power_of(thermal) * kc_t + power_of(other) * kc_for(other)
    else:
        total += power_of(power) * kc_for(power)
    largest = max((d["power_w"] for d in devices), default=0)
    total = max(total, largest)
    p = q = 0.0
    for d in devices:
        pw = d["power_w"] * d.get("quantity", 1) * d.get("usage_factor", 1)
        cos = d.get("cos_phi", 1)
        p += pw
        q += 0 if cos >= 1 else pw * math.sqrt(1 - cos * cos) / cos
    return total, (1.0 if p <= EPS else p / math.hypot(p, q))


# ------------------------------------------------------------------ project


ASSUMED_ZEXT = {"apartment": 0.5, "commercial": 0.5, "house": 0.8, "garageWorkshop": 0.8}


def calculate(inp):
    voltage = next(v for v in CONSTANTS["nominal_voltage_options_v"] if v["id"] == inp.get("nominal_voltage_id", "u220_380"))
    u0, ul = voltage["phase_v"], voltage["line_v"]
    supply_three = inp["supply_phases"] == "three"
    rooms = inp.get("rooms", [])
    issues = []
    devices = []
    for d in inp.get("devices", []):
        if d.get("phases", 1) == 3 and not supply_three:
            issues.append("three_phase_device_on_single_phase_supply")
        else:
            devices.append(d)
    supply = inp.get("supply") or {}
    defaults = inp.get("cable_defaults") or {}
    zext = supply.get("external_loop_impedance_ohm")
    assumed = zext is None
    if assumed:
        zext = ASSUMED_ZEXT[inp["object_type"]]

    circuits = []
    for c in build_circuits(devices, rooms, u0, ul):
        design = demand = (0.0, 0.0)
        extra = 0.0
        for d in c["devices"]:
            v = device_vector(d, u0, ul)
            design = add(design, v)
            demand = add(demand, device_vector(d, u0, ul, demand=True))
            extra = max(extra, (d.get("inrush_multiple", 1) - 1) * magnitude(v))
        ib = magnitude(design)
        cos = 1.0 if ib == 0 else design[0] / ib
        start = ib + extra
        phases = 3 if any(d.get("phases", 1) == 3 for d in c["devices"]) else 1
        settings = (inp.get("circuit_settings") or {}).get(c["id"], {})
        rated = settings.get("breaker_a") or rated_at_or_above(max(ib, MIN_BREAKER[c["purpose"]])) or float(RATINGS[-1])
        curves = [settings["curve"].upper()] if settings.get("curve") else curve_options(start, rated)
        socket = any(d.get("connection", "socket") == "socket" for d in c["devices"])
        rcd = needs_rcd(c)
        protection = settings.get("protection") or (
            "mcb" if not rcd else {"rcboPerCircuit": "rcbo", "rcdPerCircuit": "mcbAndRcd",
                                   "groupedRcd": "mcbUnderGroupRcd"}[inp.get("rcd_strategy", "rcboPerCircuit")])
        material = settings.get("material") or defaults.get("material", "copper")
        spec = dict(
            phases=phases, lighting=c["purpose"] == "lighting", ib=ib, cos=cos, u0=u0, **{"in": rated},
            material=material, insulation=settings.get("insulation") or defaults.get("insulation", "pvc"),
            method=settings.get("installation_method_id") or defaults.get("installation_method_id", "plaster_direct"),
            ambient=settings.get("ambient_temperature_c", defaults.get("ambient_temperature_c", 30)),
            grouped=settings.get("grouped_circuits") or defaults.get("grouped_circuits", 1),
            soil=defaults.get("soil_resistivity_k_m_per_w", 2.5),
            min_section=min_section(c, material),
            length=settings.get("length_m", defaults.get("length_m")),
            zext=zext,
        )
        cable, curve = select_cable(spec, curves)
        checks = dict(cable["checks"])
        checks["loadVsBreaker"] = "passed" if ib <= rated + EPS else "failed"
        if socket:
            checks["socketRating"] = "passed" if rated <= 16 + EPS else "failed"
        checks["startingCurrent"] = "passed" if start < TRIP[curves[0]]["min"] * rated - EPS else "failed"
        if protection != "mcb":
            leak = 0.4 * ib + 0.01 * (spec["length"] or 0)
            checks["rcdLeakage"] = "passed" if leak <= 10 + EPS else "warning"
        statuses = set(checks.values())
        if "failed" in statuses:
            status = "failed"
        elif checks["voltageDrop"] == "notEvaluated" or checks["faultDisconnection"] == "notEvaluated":
            status = "preliminary"
        elif assumed:
            status = "requiresReview"
        elif "warning" in statuses:
            status = "warning"
        else:
            status = "passed"
        circuits.append(dict(
            id=c["id"], purpose=c["purpose"], device_ids=[d["id"] for d in c["devices"]], phases=phases,
            design_current_a=ib, starting_current_a=start, cos_phi=cos, demand_current_a=magnitude(demand),
            breaker_a=rated, curve=curve.lower(), protection=protection, section_mm2=cable["section"],
            pe_section_mm2=cable["pe"], ampacity_a=cable["iz"], voltage_drop_percent=cable["vd"],
            voltage_drop_limit_percent=cable["limit"], loop_impedance_ohm=cable["zs"],
            fault_current_min_a=cable["ik"], status=status, checks=checks,
        ))

    installed = sum(d["power_w"] * d.get("quantity", 1) for d in devices)
    by_devices = sum(d["power_w"] * d.get("quantity", 1) * d.get("usage_factor", 1) for d in devices)
    if inp["object_type"] in ("apartment", "house"):
        normative, cos = residential_demand(inp, devices, installed)
    else:
        normative, cos = public_demand(inp, devices)
    incomer = dict(installed_power_w=installed, demand_by_devices_w=by_devices, demand_normative_w=normative, cos_phi=cos)
    breaker = None
    if not supply_three:
        design = normative / (u0 * cos)
        design = max([design] + [c["design_current_a"] for c in circuits])
        breaker = supply.get("incomer_breaker_a") or rated_at_or_above(design)
        incomer.update(design_current_a=design, breaker_a=breaker)
    allowed = supply.get("allowed_power_kw")
    if allowed is not None and normative <= allowed * 1000 + EPS and by_devices > allowed * 1000 + EPS:
        issues.append("demand_by_devices_exceeds_allowed")
    fire = inp.get("fire_rcd_at_input")
    if fire is None:
        fire = inp["object_type"] in ("house", "garageWorkshop")
    return dict(issues=issues, incomer=incomer, fire_rcd=bool(fire), circuits=circuits)
