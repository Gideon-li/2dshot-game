#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""V122: offline inquiry template coverage self-check. Run: python3 logic/check_offline_templates.py"""
import json, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
# Prefer repo root; fallback to /workspace/xinglin-mowen
if not (ROOT / "logic/slice_logic.json").exists():
    ROOT = Path("/workspace/xinglin-mowen")

def main() -> int:
    logic = json.loads((ROOT / "logic/slice_logic.json").read_text(encoding="utf-8"))
    chars = json.loads((ROOT / "patients/slice_characters.json").read_text(encoding="utf-8"))
    patients = {p["id"]: p for p in chars.get("patients", [])}
    fails, warns, rows = [], [], []
    for case in logic.get("cases", []):
        cid, bind = case["id"], case.get("bind_character_id")
        wen = case.get("clues", {}).get("wen_ask", {})
        anchors, never = wen.get("inquiry_anchor", []), wen.get("never_say", [])
        issues = []
        if not bind or bind not in patients:
            issues.append("missing_bind"); fails.append(f"{cid}: missing bind")
        if len(anchors) < 3:
            issues.append("anchors"); fails.append(f"{cid}: anchors {len(anchors)}")
        if len(never) < 3:
            issues.append("never_say"); fails.append(f"{cid}: never_say {len(never)}")
        pat = patients.get(bind, {})
        if pat:
            for loc in ("zh", "en", "ja"):
                w = pat.get("ask_wrappers", {}).get(loc, [])
                if len(w) < 3:
                    issues.append(f"wrappers.{loc}"); fails.append(f"{bind}: wrappers.{loc}")
                elif not any("{sym}" in str(x) for x in w):
                    issues.append(f"sym.{loc}"); fails.append(f"{bind}: no {{sym}} in {loc}")
            def lt(d, k="zh"):
                return str((d or {}).get(k) or (d or {}).get("zh") or "") if isinstance(d, dict) else str(d or "")
            if not lt(pat.get("opening")): issues.append("opening"); fails.append(f"{bind}: opening")
            if not lt(pat.get("dodge")): issues.append("dodge"); fails.append(f"{bind}: dodge")
            # smoke one offline reply
            wrap = (pat.get("ask_wrappers", {}).get("zh") or ["{sym}"])[0]
            sym = str(anchors[0]) if anchors else "……"
            reply = str(wrap).replace("{sym}", sym)
            if not reply.strip():
                issues.append("empty"); fails.append(f"{cid}: empty template")
            for n in never:
                if str(n) and str(n) in reply:
                    issues.append("leak"); fails.append(f"{cid}: leak {n}")
        rows.append({"case_id": cid, "bind": bind, "ok": not issues, "issues": issues})
    report = {
        "id": "offline_template_coverage_v122",
        "pass": not fails,
        "fail_count": len(fails),
        "fails": fails,
        "cases": rows,
        "provider_note": "prompt/templates provider-agnostic",
    }
    out = ROOT / "logic/offline_coverage_report.json"
    # merge with existing prompt_contract if present
    prev = {}
    if out.exists():
        try:
            prev = json.loads(out.read_text(encoding="utf-8"))
        except Exception:
            prev = {}
    if "prompt_contract" in prev:
        report["prompt_contract"] = prev["prompt_contract"]
    out.write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("PASS" if report["pass"] else "FAIL", f"fails={len(fails)}")
    for f in fails:
        print(" -", f)
    return 0 if report["pass"] else 1

if __name__ == "__main__":
    sys.exit(main())
