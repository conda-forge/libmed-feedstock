#!/usr/bin/env python3
"""Remove 'bidon' dummy parameters from PPRO_NT C function signatures.

When libmed is compiled WITHOUT /iface:mixed_str_len_arg (the default for ifx),
Fortran hidden string lengths are passed at the END of the argument list instead
of immediately after each string argument.  The PPRO_NT C wrappers in src/cfi/
originally included 'unsigned int bidon' parameters to absorb the mixed-position
hidden lengths.  Without /iface:mixed_str_len_arg these parameters must be
removed so that the remaining arguments align correctly.

The extra hidden string-length values that Fortran still appends at the end of
the call are harmlessly ignored by the C functions on x86-64.

Usage: python fix_iface.py <source_dir>
"""

import glob
import os
import re
import sys

# Patterns for bidon parameter declarations (with optional const/comma)
# Handles both standalone lines and inline occurrences:
#   "const unsigned int bidon,"      (standalone line)
#   "char *name,  unsigned int bidon1, med_int *lon1,"  (inline)
_BIDON_PARAM = re.compile(
    r",?\s*(?:const\s+)?unsigned\s+int\s+bidon\d*\b\s*,?"
)


def strip_bidon(filepath):
    """Remove bidon parameter declarations from C function signatures."""
    with open(filepath, "r") as f:
        content = f.read()

    def _replace(m):
        text = m.group(0)
        # If the match has commas on both sides, keep one comma
        has_leading_comma = text.lstrip().startswith(",")
        has_trailing_comma = text.rstrip().endswith(",")
        if has_leading_comma and has_trailing_comma:
            return ","
        return ""

    new_content, count = _BIDON_PARAM.subn(_replace, content)

    # Clean up lines that are now empty or contain only whitespace
    lines = new_content.split("\n")
    cleaned = []
    for line in lines:
        if line.strip() == "":
            cleaned.append(line)
        else:
            cleaned.append(line)
    new_content = "\n".join(cleaned)

    if count:
        with open(filepath, "w") as f:
            f.write(new_content)
        print(f"  {filepath}: removed {count} bidon parameter(s)")

    return count


def main():
    src_dir = sys.argv[1] if len(sys.argv) > 1 else "."
    cfi_dir = os.path.join(src_dir, "src", "cfi")

    if not os.path.isdir(cfi_dir):
        print(f"WARNING: {cfi_dir} not found")
        return

    total = 0
    c_files = sorted(glob.glob(os.path.join(cfi_dir, "*.c")))
    for path in c_files:
        total += strip_bidon(path)

    print(f"Total: removed {total} bidon parameter(s) across {len(c_files)} file(s)")


if __name__ == "__main__":
    main()
