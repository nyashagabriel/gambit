#!/usr/bin/env python3
"""
fix_const_errors.py
-------------------
Fixes Dart `invalid_constant` errors caused by `context` being used
inside `const` expressions.

For each flagged (file, line) pair it scans backward from the error line
to find the nearest `const ` keyword (same line first, then previous lines)
and removes it.

Usage:
    python3 fix_const_errors.py
Run this from any directory — paths are hardcoded relative to the project root
or edit BASE below to match your project root.
"""

import re
from pathlib import Path
from collections import defaultdict

# ── Edit this to match your Flutter project root ──────────────────────────────
BASE = Path("/home/nyashagabriel/GambitTSL/gambit")
# ─────────────────────────────────────────────────────────────────────────────

# All error locations extracted from the diagnostics JSON (file → set of 1-based lines)
ERRORS: dict[str, list[int]] = defaultdict(list)

raw = [
    ("lib/features/company_admin/admin_dashboard.dart", [
        187, 649, 657, 664, 687, 700, 710, 718, 750, 870,
        1071, 1079, 1086, 1109, 1123, 1131,
        1214, 1222, 1229, 1254, 1268, 1276, 1285,
        1365, 1373, 1385, 1412, 1420, 1428,
    ]),
    ("lib/features/company_admin/trip_form.dart", [
        185, 193, 209, 229, 237,
    ]),
    ("lib/features/staff/docs_screen.dart", [
        166, 211, 228, 347, 399, 442, 458, 554, 566, 575, 603,
    ]),
    ("lib/features/staff/staff_dashboard.dart", [
        252, 309, 321, 442, 465, 480, 668, 675, 683,
    ]),
    ("lib/features/super_admin/super_dashboard.dart", [
        285, 664, 708, 716, 726,
    ]),
]

for rel, lines in raw:
    for ln in lines:
        ERRORS[rel].append(ln)


def remove_const_near(lines: list[str], error_line: int) -> bool:
    """
    Given 1-based error_line, scan backward (inclusive) to remove the
    first `const ` keyword found on the same or a preceding line.
    Returns True if a replacement was made.
    """
    idx = error_line - 1  # convert to 0-based
    for i in range(idx, max(idx - 15, -1), -1):
        line = lines[i]
        # Match `const ` but NOT `// const` (already commented out)
        new_line, count = re.subn(r'\bconst\s+', '', line, count=1)
        if count:
            lines[i] = new_line
            return True
    return False


total_fixed = 0
total_skipped = 0

for rel_path, error_lines in ERRORS.items():
    full_path = BASE / rel_path
    if not full_path.exists():
        print(f"  [SKIP] File not found: {full_path}")
        total_skipped += len(error_lines)
        continue

    with open(full_path, "r", encoding="utf-8") as f:
        lines = f.readlines()

    file_fixes = 0
    # Sort descending so earlier lines aren't shifted by edits to later lines
    for err_ln in sorted(set(error_lines), reverse=True):
        if remove_const_near(lines, err_ln):
            file_fixes += 1
        else:
            print(f"  [WARN] Could not find `const` near {rel_path}:{err_ln}")

    with open(full_path, "w", encoding="utf-8") as f:
        f.writelines(lines)

    total_fixed += file_fixes
    print(f"  [OK] {rel_path}  ({file_fixes} fixes)")

print(f"\nDone. {total_fixed} const keywords removed, {total_skipped} errors skipped.")
print("Run `flutter analyze` to verify.")