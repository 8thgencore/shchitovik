"""Builds device_catalog.json and room_templates.json (source of truth for these datasets).

Values are an engineering estimate of typical nameplate data; they are reviewed at the
verification stage. Usage: python3 -I tools/norms_extract/build_reference_catalogs.py <out_dir>
"""
import json
import os
import sys

DATASET_VERSION = "2026.10-1"

# id, name, kind, power_w, phases, cos_phi, usage_factor, inrush_multiple, connection, dedicated_line
DEVICES = [
    ("led_ceiling_light", "Светильник светодиодный потолочный", "lighting", 40, 1, 0.9, 1.0, 1, "fixed", "no"),
    ("led_spot", "Точечный светильник светодиодный", "lighting", 8, 1, 0.9, 1.0, 1, "fixed", "no"),
    ("led_chandelier", "Люстра светодиодная", "lighting", 80, 1, 0.9, 1.0, 1, "fixed", "no"),
    ("led_strip", "Светодиодная лента (с блоком питания)", "lighting", 50, 1, 0.9, 1.0, 1, "fixed", "no"),
    ("outdoor_light", "Уличный светильник", "lighting", 30, 1, 0.9, 1.0, 1, "fixed", "no"),
    ("signboard", "Световая вывеска", "lighting", 300, 1, 0.9, 1.0, 1, "fixed", "no"),
    ("socket_point", "Розетка общего назначения (условная нагрузка)", "socket", 200, 1, 0.95, 0.3, 1, "socket", "no"),
    ("socket_point_kitchen", "Розетка кухонная (условная нагрузка)", "socket", 500, 1, 0.95, 0.3, 1, "socket", "no"),
    ("electric_stove_1ph", "Электроплита (однофазная)", "electric_stove", 8500, 1, 1.0, 0.65, 1, "fixed", "required"),
    ("electric_stove_3ph", "Электроплита (трёхфазная)", "electric_stove", 10000, 3, 1.0, 0.65, 1, "fixed", "required"),
    ("induction_cooktop", "Варочная панель индукционная", "cooktop", 7200, 1, 0.98, 0.65, 1, "fixed", "required"),
    ("oven", "Духовой шкаф", "oven", 3500, 1, 1.0, 0.8, 1, "fixed", "required"),
    ("commercial_oven_3ph", "Пароконвектомат / печь (трёхфазная)", "oven", 10000, 3, 1.0, 0.7, 1, "fixed", "required"),
    ("microwave", "Микроволновая печь", "kitchen_appliance", 1200, 1, 0.95, 0.3, 1, "socket", "no"),
    ("kettle", "Электрочайник", "kitchen_appliance", 2000, 1, 1.0, 0.3, 1, "socket", "no"),
    ("coffee_machine", "Кофемашина", "kitchen_appliance", 1500, 1, 1.0, 0.3, 1, "socket", "no"),
    ("refrigerator", "Холодильник", "refrigeration", 300, 1, 0.8, 0.5, 5, "socket", "no"),
    ("freezer", "Морозильный ларь", "refrigeration", 250, 1, 0.8, 0.5, 5, "socket", "no"),
    ("display_fridge", "Холодильная витрина", "refrigeration", 1000, 1, 0.8, 0.7, 5, "fixed", "recommended"),
    ("dishwasher", "Посудомоечная машина", "dishwasher", 2100, 1, 0.98, 0.6, 2, "socket", "recommended"),
    ("washing_machine", "Стиральная машина", "washing_machine", 2200, 1, 0.9, 0.6, 3, "socket", "recommended"),
    ("tumble_dryer", "Сушильная машина", "dryer", 2600, 1, 0.95, 0.5, 2, "socket", "recommended"),
    ("water_heater_storage", "Водонагреватель накопительный", "water_heater", 2000, 1, 1.0, 0.8, 1, "socket", "recommended"),
    ("water_heater_instant_1ph", "Водонагреватель проточный (однофазный)", "water_heater", 6000, 1, 1.0, 0.5, 1, "fixed", "required"),
    ("water_heater_instant_3ph", "Водонагреватель проточный (трёхфазный)", "water_heater", 12000, 3, 1.0, 0.5, 1, "fixed", "required"),
    ("electric_boiler_1ph", "Электрокотёл отопления (однофазный)", "heating_boiler", 6000, 1, 1.0, 0.8, 1, "fixed", "required"),
    ("electric_boiler_3ph", "Электрокотёл отопления (трёхфазный)", "heating_boiler", 12000, 3, 1.0, 0.8, 1, "fixed", "required"),
    ("convector", "Электроконвектор", "heater", 1500, 1, 1.0, 0.7, 1, "socket", "no"),
    ("towel_warmer", "Полотенцесушитель электрический", "heater", 300, 1, 1.0, 0.7, 1, "fixed", "no"),
    ("floor_heating_bathroom", "Тёплый пол (ванная)", "floor_heating", 800, 1, 1.0, 0.7, 1, "fixed", "recommended"),
    ("floor_heating_room", "Тёплый пол (комната)", "floor_heating", 1500, 1, 1.0, 0.7, 1, "fixed", "recommended"),
    ("air_conditioner_small", "Кондиционер сплит 2,5 кВт (холод)", "air_conditioner", 900, 1, 0.9, 0.7, 3, "fixed", "recommended"),
    ("air_conditioner_large", "Кондиционер сплит 7 кВт (холод)", "air_conditioner", 2300, 1, 0.9, 0.7, 3, "fixed", "required"),
    ("bathroom_fan", "Вытяжной вентилятор", "ventilation", 40, 1, 0.8, 0.5, 2, "fixed", "no"),
    ("kitchen_hood", "Вытяжка кухонная", "ventilation", 250, 1, 0.85, 0.5, 2, "socket", "no"),
    ("ventilation_unit", "Приточно-вытяжная установка", "ventilation", 500, 1, 0.85, 0.8, 3, "fixed", "recommended"),
    ("well_pump", "Скважинный насос", "pump", 1100, 1, 0.8, 0.5, 6, "fixed", "required"),
    ("circulation_pump", "Циркуляционный насос отопления", "pump", 100, 1, 0.9, 1.0, 2, "fixed", "no"),
    ("sauna_heater", "Электрокаменка", "sauna_heater", 9000, 3, 1.0, 0.8, 1, "fixed", "required"),
    ("ev_charger_1ph", "Зарядная станция электромобиля 7,4 кВт", "ev_charger", 7400, 1, 0.99, 1.0, 1, "fixed", "required"),
    ("ev_charger_3ph", "Зарядная станция электромобиля 11 кВт", "ev_charger", 11000, 3, 0.99, 1.0, 1, "fixed", "required"),
    ("computer", "Компьютер с монитором", "electronics", 400, 1, 0.95, 0.5, 1, "socket", "no"),
    ("tv", "Телевизор", "electronics", 150, 1, 0.95, 0.5, 1, "socket", "no"),
    ("network_equipment", "Сетевое оборудование (роутер, коммутатор)", "electronics", 50, 1, 0.95, 1.0, 1, "socket", "no"),
    ("cash_register", "Кассовый терминал", "electronics", 100, 1, 0.95, 1.0, 1, "socket", "no"),
    ("server_rack", "Серверная стойка", "electronics", 2000, 1, 0.95, 0.8, 1, "fixed", "required"),
    ("power_tool", "Электроинструмент", "power_tool", 1500, 1, 0.85, 0.3, 6, "socket", "no"),
    ("welder", "Сварочный инвертор", "welder", 5000, 1, 0.9, 0.3, 2, "socket", "required"),
    ("air_compressor", "Компрессор воздушный", "motor", 2200, 1, 0.8, 0.4, 6, "socket", "recommended"),
    ("machine_tool_3ph", "Станок (трёхфазный)", "motor", 3000, 3, 0.8, 0.4, 6, "fixed", "required"),
    ("gate_drive", "Привод ворот", "motor", 500, 1, 0.8, 0.2, 4, "fixed", "no"),
    ("hair_dryer_salon", "Фен профессиональный", "personal_care", 2000, 1, 1.0, 0.5, 1, "socket", "no"),
]

# id, name, room_kind, [(device_id, count)]
ROOMS = [
    ("kitchen", "Кухня", "kitchen", [("led_ceiling_light", 1), ("led_strip", 1), ("socket_point_kitchen", 4),
                                     ("refrigerator", 1), ("microwave", 1), ("kettle", 1), ("dishwasher", 1),
                                     ("oven", 1), ("induction_cooktop", 1), ("kitchen_hood", 1)]),
    ("bathroom", "Ванная", "bathroom", [("led_spot", 4), ("socket_point", 1), ("washing_machine", 1),
                                        ("water_heater_storage", 1), ("floor_heating_bathroom", 1),
                                        ("bathroom_fan", 1), ("towel_warmer", 1)]),
    ("toilet", "Санузел", "bathroom", [("led_spot", 2), ("bathroom_fan", 1)]),
    ("living_room", "Гостиная", "standard", [("led_chandelier", 1), ("led_spot", 6), ("socket_point", 6),
                                             ("tv", 1), ("air_conditioner_small", 1)]),
    ("bedroom", "Спальня", "standard", [("led_chandelier", 1), ("socket_point", 4), ("air_conditioner_small", 1)]),
    ("kids_room", "Детская", "standard", [("led_chandelier", 1), ("socket_point", 4), ("computer", 1)]),
    ("study", "Кабинет", "standard", [("led_ceiling_light", 1), ("socket_point", 4), ("computer", 1),
                                      ("network_equipment", 1)]),
    ("hallway", "Прихожая / коридор", "standard", [("led_spot", 4), ("socket_point", 2)]),
    ("balcony", "Балкон / лоджия", "standard", [("led_ceiling_light", 1), ("socket_point", 1)]),
    ("boiler_room", "Котельная / техническое помещение", "standard",
     [("led_ceiling_light", 1), ("socket_point", 1), ("electric_boiler_3ph", 1), ("circulation_pump", 1),
      ("well_pump", 1)]),
    ("sauna", "Сауна", "bathroom", [("led_ceiling_light", 1), ("sauna_heater", 1)]),
    ("garage", "Гараж", "garage", [("led_ceiling_light", 2), ("socket_point", 3), ("power_tool", 1), ("gate_drive", 1)]),
    ("workshop", "Мастерская", "garage", [("led_ceiling_light", 3), ("socket_point", 4), ("machine_tool_3ph", 1),
                                          ("air_compressor", 1), ("welder", 1)]),
    ("outdoor", "Улица / участок", "outdoor", [("outdoor_light", 4), ("socket_point", 2)]),
    ("office", "Офисное помещение", "standard", [("led_ceiling_light", 6), ("socket_point", 8), ("computer", 4),
                                                 ("network_equipment", 1), ("air_conditioner_small", 1)]),
    ("sales_area", "Торговый зал", "standard", [("led_ceiling_light", 10), ("socket_point", 4), ("display_fridge", 2),
                                                ("cash_register", 1), ("signboard", 1), ("air_conditioner_large", 1)]),
    ("server_room", "Серверная", "standard", [("led_ceiling_light", 1), ("socket_point", 2), ("server_rack", 1),
                                              ("air_conditioner_small", 1)]),
    ("salon", "Салон / парикмахерская", "standard", [("led_ceiling_light", 6), ("socket_point", 6),
                                                     ("hair_dryer_salon", 3), ("water_heater_storage", 1),
                                                     ("air_conditioner_small", 1)]),
    ("cafe_kitchen", "Кухня кафе", "kitchen", [("led_ceiling_light", 4), ("socket_point_kitchen", 6),
                                               ("commercial_oven_3ph", 1), ("display_fridge", 1), ("dishwasher", 1),
                                               ("ventilation_unit", 1)]),
]


def device_catalog():
    devices = [
        {"id": i, "name": n, "kind": k, "power_w": p, "phases": ph, "cos_phi": cos, "usage_factor": ku,
         "inrush_multiple": inr, "connection": conn, "dedicated_line": ded}
        for (i, n, k, p, ph, cos, ku, inr, conn, ded) in DEVICES
    ]
    return {
        "dataset": "device_catalog",
        "dataset_version": DATASET_VERSION,
        "description": "Справочник типовых электроприёмников для быстрого ввода.",
        "source": {"documents": ["engineering-estimate", "sp-256-1325800-2016"],
                   "clauses": ["СП 256: 7.1.12, табл. 7.12 (ориентиры cos φ)"]},
        "notes": [
            "Мощности, cos φ, usage_factor и inrush_multiple – инженерная оценка по типовым паспортным данным; пользователь может изменить.",
            "usage_factor (ku) используется только для оценки нагрузки ввода «по приборам»; групповые линии считаются с Kс = 1 (СП 256, 7.2.2 и табл. 7.7).",
            "inrush_multiple – кратность пускового тока к номинальному (для выбора характеристики B/C/D).",
            "dedicated_line: required – всегда отдельная линия; recommended – по умолчанию отдельная, можно объединить; no – общая группа.",
            "socket_point – условная нагрузка розетки; нагрузка розеточной группы ограничивается её автоматом.",
        ],
        "kinds": sorted({d["kind"] for d in devices}),
        "devices": devices,
    }


def room_templates(device_ids):
    rooms = []
    for rid, name, kind, devices in ROOMS:
        for d, _ in devices:
            assert d in device_ids, d
        rooms.append({"id": rid, "name": name, "room_kind": kind,
                      "devices": [{"device_id": d, "count": c} for d, c in devices]})
    return {
        "dataset": "room_templates",
        "dataset_version": DATASET_VERSION,
        "description": "Шаблоны помещений с типовым набором электроприёмников.",
        "source": {"documents": ["engineering-estimate", "sp-256-1325800-2016"],
                   "clauses": ["СП 256: 15.28 (число розеток), прил. А (УДТ)"]},
        "notes": [
            "room_kind влияет на правила УДТ: bathroom – ванные, душевые, сауны (ГОСТ Р 50571.7.701, СП 256 А.4.15); "
            "outdoor – наружные розетки (СП 256 А.1.6, А.5.4); garage – гаражи и мастерские (СП 256 А.5.4); kitchen – кухни.",
            "Наборы приборов – стартовые, пользователь редактирует их в мастере.",
        ],
        "room_kinds": ["standard", "kitchen", "bathroom", "outdoor", "garage"],
        "rooms": rooms,
    }


def main():
    out = sys.argv[1]
    catalog = device_catalog()
    templates = room_templates({d["id"] for d in catalog["devices"]})
    for name, data in (("device_catalog.json", catalog), ("room_templates.json", templates)):
        with open(os.path.join(out, name), "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=1)
            f.write("\n")
    print(len(catalog["devices"]), len(templates["rooms"]))


if __name__ == "__main__":
    main()
