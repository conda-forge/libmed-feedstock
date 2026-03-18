#!/usr/bin/env python3
"""Add lowercase+underscore aliases to auto-generated .def files in the build tree.

When libmed is compiled with ifx defaults (UPPERCASE Fortran symbols), the
auto-generated .def files (from CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS) export e.g.
'MFACRE'. But code_aster, compiled with /names:lowercase /assume:underscore,
expects 'mfacre_'.

This script finds all exports.def files in the CMake build tree, and adds
    mfacre_ = MFACRE
aliases so that after re-linking, the DLLs export both names.

Usage: python fix_exports.py <build_dir>
"""

import glob
import os
import sys


def process_def_file(def_path):
    """Read a .def file and add lowercase+underscore aliases for exports."""
    with open(def_path, "r") as f:
        content = f.read()
    lines = content.splitlines(keepends=True)

    # First pass: collect all existing symbol names
    in_exports = False
    existing_symbols = set()
    for line in lines:
        stripped = line.strip()
        if stripped.upper() == "EXPORTS":
            in_exports = True
            continue
        if in_exports and stripped:
            sym = stripped.split()[0]
            existing_symbols.add(sym)

    if not existing_symbols:
        return 0

    # Second pass: insert alias lines after each export
    in_exports = False
    new_lines = []
    n_aliases = 0
    for line in lines:
        new_lines.append(line)
        stripped = line.strip()
        if stripped.upper() == "EXPORTS":
            in_exports = True
            continue
        if in_exports and stripped:
            sym = stripped.split()[0]
            alias = sym.lower() + "_"
            # Only add alias if it differs from the original and doesn't exist
            if alias != sym and alias not in existing_symbols:
                indent = line[: len(line) - len(line.lstrip())]
                if not indent:
                    indent = "    "
                new_lines.append(f"{indent}{alias} = {sym}\n")
                existing_symbols.add(alias)
                n_aliases += 1

    if n_aliases > 0:
        with open(def_path, "w") as f:
            f.writelines(new_lines)
        print(f"  {def_path}: added {n_aliases} aliases")

    return n_aliases


def main():
    build_dir = sys.argv[1] if len(sys.argv) > 1 else "."

    # Find all auto-generated exports.def files from CMAKE_WINDOWS_EXPORT_ALL_SYMBOLS
    def_files = glob.glob(
        os.path.join(build_dir, "**", "exports.def"), recursive=True
    )

    # Also look for any other .def files
    if not def_files:
        def_files = glob.glob(
            os.path.join(build_dir, "**", "*.def"), recursive=True
        )

    if not def_files:
        print(f"WARNING: No .def files found in {build_dir}")
        # List the directory structure for debugging
        for root, dirs, files in os.walk(build_dir):
            depth = root.replace(build_dir, "").count(os.sep)
            if depth < 4:
                for f in files:
                    if f.endswith(".def"):
                        print(f"  Found: {os.path.join(root, f)}")
        return

    total = 0
    for def_file in def_files:
        n = process_def_file(def_file)
        total += n

    print(f"Total: {total} aliases added across {len(def_files)} .def file(s)")


if __name__ == "__main__":
    main()
