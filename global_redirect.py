#!/usr/bin/env python3
"""Redirect Instagram's Reels tab to Direct Messages.

Instagram's main tab host resolves each tab to a fragment by string name.  The
Reels tab is ``fragment_clips``; rewriting that literal to
``fragment_direct_tab`` makes every Reels entry point open the DM inbox instead.

Only ``const-string`` operands are rewritten, so unrelated text that happens to
contain the token is left alone, and the InstaFree classes are skipped.  Reels
shared inside DMs still play: they never go through the tab host.

Usage:
    global_redirect.py <decoded-apk-dir>
"""

import os
import re
import sys

SOURCE_FRAGMENT = "fragment_clips"
TARGET_FRAGMENT = "fragment_direct_tab"
SKIP_PACKAGE = os.path.join("com", "instafree")

# `const-string v0, "fragment_clips"` / `const-string/jumbo v0, "fragment_clips"`
CONST_STRING_RE = re.compile(
    r'^([ \t]*const-string(?:/jumbo)?[ \t]+[vp]\d+,[ \t]*)"%s"([ \t]*)$' % re.escape(SOURCE_FRAGMENT)
)
QUOTED_SOURCE = '"%s"' % SOURCE_FRAGMENT
QUOTED_TARGET = '"%s"' % TARGET_FRAGMENT


def is_instafree_package(directory):
    """Our own classes, without also matching a package that merely starts the same."""
    tail = os.sep + SKIP_PACKAGE
    return directory.endswith(tail) or (tail + os.sep) in directory


def smali_roots(work_dir):
    for entry in sorted(os.listdir(work_dir)):
        if entry == "smali" or entry.startswith("smali_classes"):
            path = os.path.join(work_dir, entry)
            if os.path.isdir(path):
                yield path


def redirect(work_dir, any_literal=False):
    """Rewrite the Reels fragment name.

    By default only ``const-string`` operands are touched. ``any_literal``
    widens that to the quoted token anywhere in a smali file, which is the
    fallback for a build that carries the name in some other construct.
    """
    files_changed = 0
    occurrences = 0

    for root_dir in smali_roots(work_dir):
        for root, _dirs, files in os.walk(root_dir):
            if is_instafree_package(root):
                continue
            for name in files:
                if not name.endswith(".smali"):
                    continue
                path = os.path.join(root, name)
                with open(path, "r", encoding="utf-8", errors="surrogateescape") as handle:
                    text = handle.read()
                if SOURCE_FRAGMENT not in text:
                    continue

                if any_literal:
                    hits = text.count(QUOTED_SOURCE)
                    lines = [text.replace(QUOTED_SOURCE, QUOTED_TARGET)]
                else:
                    lines = text.split("\n")
                    hits = 0
                    for index, line in enumerate(lines):
                        match = CONST_STRING_RE.match(line)
                        if match:
                            lines[index] = '%s"%s"%s' % (
                                match.group(1),
                                TARGET_FRAGMENT,
                                match.group(2),
                            )
                            hits += 1

                if hits:
                    with open(path, "w", encoding="utf-8", errors="surrogateescape") as handle:
                        handle.write("\n".join(lines))
                    files_changed += 1
                    occurrences += hits

    return files_changed, occurrences


def main(argv):
    if len(argv) != 2:
        print(__doc__)
        return 2

    work_dir = argv[1]
    if not os.path.isdir(work_dir):
        print("  Error: not a directory: %s" % work_dir)
        return 1

    files_changed, occurrences = redirect(work_dir)

    if not occurrences:
        # The name is still there but not as a const-string operand: rewrite the
        # quoted token wherever it appears rather than shipping a live Reels tab.
        files_changed, occurrences = redirect(work_dir, any_literal=True)
        if occurrences:
            print("  Note: no const-string operand matched; rewrote the quoted")
            print("  literal instead. Worth re-checking how the tab host resolves")
            print("  fragments in this Instagram version.")

    if not occurrences:
        print('  Error: no "%s" literal found.' % SOURCE_FRAGMENT)
        print("  Instagram renamed the Reels fragment; the redirect needs a new")
        print("  target before this version can be patched.")
        return 1

    print(
        "  Redirected %d reference(s) to %s across %d file(s)."
        % (occurrences, TARGET_FRAGMENT, files_changed)
    )
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
