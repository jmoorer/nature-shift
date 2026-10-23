#!/usr/bin/env python3
"""Convert 'Nature Transformations.xlsx' to data/catalog/catalog.json (stdlib only).

Every sheet becomes {headers, rows}; each row is a dict keyed by header, with
cell positions respected (blank cells stay empty, not shifted). Rows are raw
reference data: nothing here is a playable ability. Usage:
    python3 tools/export_catalog.py
"""
import json
import re
import sys
import zipfile
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "Nature Transformations.xlsx"
OUT = ROOT / "data" / "catalog" / "catalog.json"
M = "{http://schemas.openxmlformats.org/spreadsheetml/2006/main}"
R = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}"


def col_index(ref: str) -> int:
    letters = re.match(r"[A-Z]+", ref).group(0)
    n = 0
    for ch in letters:
        n = n * 26 + ord(ch) - 64
    return n - 1


def main() -> int:
    with zipfile.ZipFile(SRC) as z:
        strings = []
        if "xl/sharedStrings.xml" in z.namelist():
            for si in ET.fromstring(z.read("xl/sharedStrings.xml")):
                strings.append("".join(t.text or "" for t in si.iter(M + "t")))
        rels = {
            r.get("Id"): r.get("Target")
            for r in ET.fromstring(z.read("xl/_rels/workbook.xml.rels"))
        }
        sheets = {}
        for sh in ET.fromstring(z.read("xl/workbook.xml")).iter(M + "sheet"):
            target = rels[sh.get(R + "id")].lstrip("/")
            path = target if target.startswith("xl/") else "xl/" + target
            rows = []
            for row in ET.fromstring(z.read(path)).iter(M + "row"):
                cells = {}
                for c in row:
                    v = c.find(M + "v")
                    if v is None:
                        continue
                    cells[col_index(c.get("r"))] = (
                        strings[int(v.text)] if c.get("t") == "s" else v.text
                    )
                if cells:
                    rows.append([cells.get(i, "") for i in range(max(cells) + 1)])
            if not rows:
                continue
            headers = rows[0]
            sheets[sh.get("name")] = {
                "headers": headers,
                "rows": [
                    {h or f"col{i}": (r[i] if i < len(r) else "") for i, h in enumerate(headers)}
                    for r in rows[1:]
                ],
            }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(
        json.dumps({"source_file": SRC.name, "sheets": sheets}, ensure_ascii=False, indent=1),
        encoding="utf-8",
    )
    for name, s in sheets.items():
        print(f"{name}: {len(s['rows'])} rows")
    return 0


if __name__ == "__main__":
    sys.exit(main())
