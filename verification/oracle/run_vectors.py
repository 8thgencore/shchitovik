"""Runs the oracle over verification/vectors/*.json and compares with the Dart core output.

Usage: python3 -I verification/oracle/run_vectors.py   (exit code 1 on mismatches)
"""
import json
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import oracle  # noqa: E402

VECTORS = pathlib.Path(__file__).resolve().parent.parent / "vectors"
# Phase balancing is checked by invariants in the Dart tests, not re-implemented here.
IGNORED_ISSUES = {"phase_imbalance"}


def close(a, b):
    if a is None or b is None:
        return a is b
    if isinstance(a, (int, float)) and isinstance(b, (int, float)) and not isinstance(a, bool):
        return abs(a - b) <= 1e-9 + 1e-9 * max(abs(a), abs(b))
    return a == b


def compare(vector_id, expected, actual, mismatches):
    def diff(path, e, a):
        mismatches.append(f"{vector_id} {path}: dart={e!r} oracle={a!r}")

    e_issues = sorted(i for i in expected["issues"] if i not in IGNORED_ISSUES)
    a_issues = sorted(i for i in actual["issues"] if i not in IGNORED_ISSUES)
    if e_issues != a_issues:
        diff("issues", e_issues, a_issues)
    for key, value in expected["incomer"].items():
        if not close(value, actual["incomer"].get(key)):
            diff(f"incomer.{key}", value, actual["incomer"].get(key))
    if expected["fire_rcd"] != actual["fire_rcd"]:
        diff("fire_rcd", expected["fire_rcd"], actual["fire_rcd"])
    e_ids = [c["id"] for c in expected["circuits"]]
    a_ids = [c["id"] for c in actual["circuits"]]
    if e_ids != a_ids:
        diff("circuits", e_ids, a_ids)
        return
    for ec, ac in zip(expected["circuits"], actual["circuits"]):
        for key, value in ec.items():
            if key == "checks":
                if value != ac["checks"]:
                    diff(f"{ec['id']}.checks", value, ac["checks"])
            elif not close(value, ac.get(key)):
                diff(f"{ec['id']}.{key}", value, ac.get(key))


def main():
    mismatches = []
    total = 0
    for name in ("circuits", "projects"):
        data = json.loads((VECTORS / f"{name}.json").read_text(encoding="utf-8"))
        for v in data["vectors"]:
            total += 1
            compare(v["id"], v["expected"], oracle.calculate(v["input"]), mismatches)
    print(f"векторов: {total}, расхождений: {len(mismatches)}")
    for m in mismatches[:40]:
        print(" -", m)
    sys.exit(1 if mismatches else 0)


if __name__ == "__main__":
    main()
