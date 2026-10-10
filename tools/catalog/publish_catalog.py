"""Prepares the price catalog for the static hosting: <out>/catalog/{manifest.json, *.json}.

The manifest lists every dataset with its SHA-256; the app downloads a catalog only when
its catalog_version differs from the one in use and every checksum matches.

Usage: python3 -I tools/catalog/publish_catalog.py <out_dir>
"""
import datetime
import hashlib
import json
import pathlib
import sys

DATA = pathlib.Path(__file__).resolve().parent.parent.parent / "engine" / "estimate_core" / "data"
DATASETS = ["apparatus_catalog", "cable_catalog", "auxiliary_devices", "fallback_prices"]


def main():
    out = pathlib.Path(sys.argv[1]) / "catalog"
    out.mkdir(parents=True, exist_ok=True)
    files = {}
    for name in DATASETS:
        # Compact JSON, UTF-8; the checksum is computed over exactly the served bytes.
        content = json.dumps(json.loads((DATA / f"{name}.json").read_text(encoding="utf-8")),
                             ensure_ascii=False, separators=(",", ":"))
        (out / f"{name}.json").write_text(content, encoding="utf-8")
        files[name] = {"path": f"{name}.json", "sha256": hashlib.sha256(content.encode("utf-8")).hexdigest()}
    version = json.loads((DATA / "apparatus_catalog.json").read_text(encoding="utf-8"))["catalog_version"]
    manifest = {
        "schema_version": 1,
        "catalog_version": version,
        "published_at": datetime.datetime.now(datetime.timezone.utc).isoformat(timespec="seconds"),
        "files": files,
    }
    (out / "manifest.json").write_text(json.dumps(manifest, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"catalog {version} → {out}")


if __name__ == "__main__":
    main()
