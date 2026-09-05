#!/usr/bin/env python3
"""Make Instagram trust the re-signed APK, so deep links keep working.

Before following a link into its own content, Instagram checks that the running
APK carries Meta's signing certificate.  It wraps a certificate's SHA-256 in a
"key hash" object and looks that hash up in a hardcoded allowlist.  A re-signed
build is not in the allowlist, the check fails, and shared links (posts, reels,
profiles) silently drop to the home feed instead of opening.

The key-hash class is obfuscated, but it is the only class carrying the string
"Invalid SHA256 key hash", so it can be located by that.  The allowlist checks
are then the static methods that take key hashes and return a boolean; their
bodies are replaced with ``return true``.

This is a trust check on the app's *own* signature, not a security boundary
against anything else: it only stops Instagram from rejecting itself.

Best effort - if Instagram restructures the check the patch is skipped with a
warning and everything except deep links still works.

Usage:
    apply_signature_bypass.py <decoded-apk-dir>
"""

import os
import re
import sys

MARKER_STRING = "Invalid SHA256 key hash"
CLASS_RE = re.compile(r"^\.class\b.*?(L[^;\s]+;)\s*$")
# `.method public static A01(LX/6io;LX/6io;Z)Z`
METHOD_RE = re.compile(r"^\.method\b(?P<modifiers>[^(]*?)\s(?P<name>[^\s(]+)\((?P<params>[^)]*)\)(?P<ret>.+)$")
PARAM_RE = re.compile(r"\[*(?:L[^;]+;|[ZBSCIJFD])")


def smali_roots(work_dir):
    for entry in sorted(os.listdir(work_dir)):
        if entry == "smali" or entry.startswith("smali_classes"):
            path = os.path.join(work_dir, entry)
            if os.path.isdir(path):
                yield path


def smali_files(work_dir):
    for root_dir in smali_roots(work_dir):
        for root, _dirs, files in os.walk(root_dir):
            for name in files:
                if name.endswith(".smali"):
                    yield os.path.join(root, name)


def find_key_hash_type(work_dir):
    """Return the descriptor of the class that builds key hashes."""
    for path in smali_files(work_dir):
        with open(path, "r", encoding="utf-8", errors="surrogateescape") as handle:
            text = handle.read()
        if MARKER_STRING not in text:
            continue
        for line in text.split("\n"):
            match = CLASS_RE.match(line)
            if match:
                return match.group(1), path
    return None, None


def is_allowlist_check(modifiers, params, ret, key_hash_type):
    """A static boolean method whose arguments are key hashes (plus flags)."""
    if "static" not in modifiers or ret.strip() != "Z":
        return False
    types = PARAM_RE.findall(params)
    if "".join(types) != params.strip():
        return False
    if not types or len(types) > 3:
        return False
    if key_hash_type not in types:
        return False
    return all(param in (key_hash_type, "Z") for param in types)


def patch_file(path, key_hash_type):
    with open(path, "r", encoding="utf-8", errors="surrogateescape") as handle:
        lines = handle.read().split("\n")

    patched = []
    index = 0
    output = []
    while index < len(lines):
        line = lines[index]
        match = METHOD_RE.match(line)
        if not match or not is_allowlist_check(
            match.group("modifiers"), match.group("params"), match.group("ret"), key_hash_type
        ):
            output.append(line)
            index += 1
            continue

        end = index
        while end < len(lines) and not lines[end].startswith(".end method"):
            end += 1
        if end >= len(lines):
            output.append(line)
            index += 1
            continue

        body = "\n".join(lines[index:end])
        if "# InstaFree" in body:
            output.extend(lines[index : end + 1])
        else:
            output.extend(
                [
                    line,
                    "    .locals 1",
                    "",
                    "    # InstaFree: trust this build's own signing certificate",
                    "    const/4 v0, 0x1",
                    "",
                    "    return v0",
                    ".end method",
                ]
            )
            patched.append("%s(%s)%s" % (match.group("name"), match.group("params"), match.group("ret")))
        index = end + 1

    if patched:
        with open(path, "w", encoding="utf-8", errors="surrogateescape") as handle:
            handle.write("\n".join(output))
    return patched


def main(argv):
    if len(argv) != 2:
        print(__doc__)
        return 2

    work_dir = argv[1]
    if not os.path.isdir(work_dir):
        print("  Error: not a directory: %s" % work_dir)
        return 1

    key_hash_type, marker_path = find_key_hash_type(work_dir)
    if key_hash_type is None:
        print('  Warning: no class carrying "%s" found.' % MARKER_STRING)
        print("  Skipping the signature check bypass; deep links may open the")
        print("  home feed instead of the linked post.")
        return 0

    print("  Key hash class: %s (%s)" % (key_hash_type, os.path.basename(marker_path)))

    total = 0
    for path in smali_files(work_dir):
        for signature in patch_file(path, key_hash_type):
            total += 1
            print("  Forced true: %s in %s" % (signature, os.path.relpath(path, work_dir)))

    if not total:
        print("  Warning: no signature allowlist check matched; deep links may")
        print("  open the home feed instead of the linked post.")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
