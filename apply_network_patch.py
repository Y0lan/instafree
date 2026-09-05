#!/usr/bin/env python3
"""Inject the InstaFree network hook into Instagram's TigonServiceLayer.

Instagram routes every API request through
``com.instagram.api.tigon.TigonServiceLayer#startRequest``.  That class and
method keep their real names across releases (they are excluded from the
obfuscation map), so they are a stable anchor.

Inside ``startRequest`` the request URI is loaded out of the request object
with an ``iget-object`` of type ``Ljava/net/URI;``, inside a try block that
already catches ``IOException``.  We insert a call to
``InstaFreeHooks.throwIfBlocked(URI)`` right after that load: blocked requests
raise an IOException that Instagram handles as an ordinary network failure, so
the surface simply stays empty instead of crashing.

Usage:
    apply_network_patch.py <decoded-apk-dir | TigonServiceLayer.smali>
"""

import os
import re
import sys

HOOK_CLASS = "Lcom/instafree/InstaFreeHooks;"
HOOK_METHOD = "throwIfBlocked(Ljava/net/URI;)V"
TIGON_RELPATH = os.path.join(
    "com", "instagram", "api", "tigon", "TigonServiceLayer.smali"
)
TARGET_METHOD = "startRequest"

# `iget-object <dst>, <obj>, L...;-><field>:Ljava/net/URI;`
URI_LOAD_RE = re.compile(
    r"^[ \t]*iget-object[ \t]+([vp]\d+),[ \t]*[vp]\d+,[ \t]*L[^;]+;->[^:]+:Ljava/net/URI;[ \t]*$"
)
METHOD_START_RE = re.compile(r"^\.method\b.*?\b(?P<name>[^ (]+)\(")
TRY_START_RE = re.compile(r"^[ \t]*:try_start")


def find_tigon(target):
    """Accept either the smali file itself or a decoded-APK directory."""
    if os.path.isfile(target):
        return target
    for entry in sorted(os.listdir(target)):
        if not entry.startswith("smali"):
            continue
        candidate = os.path.join(target, entry, TIGON_RELPATH)
        if os.path.isfile(candidate):
            return candidate
    return None


def method_spans(lines):
    """Yield (name, start_index, end_index) for every method in the file."""
    start = None
    name = None
    for index, line in enumerate(lines):
        if line.startswith(".method"):
            match = METHOD_START_RE.match(line)
            start = index
            name = match.group("name") if match else ""
        elif line.startswith(".end method") and start is not None:
            yield name, start, index
            start = None
            name = None


def pick_injection_point(lines):
    """Return (line_index, register) for the URI load to hook, or None.

    Preference order: a URI load inside a try block in ``startRequest``, then
    any URI load in ``startRequest``, then any URI load inside a try block.
    """
    in_start_request = []
    in_try_anywhere = []

    for name, start, end in method_spans(lines):
        seen_try = False
        for index in range(start, end):
            line = lines[index]
            if TRY_START_RE.match(line):
                seen_try = True
                continue
            match = URI_LOAD_RE.match(line)
            if not match:
                continue
            hit = (index, match.group(1))
            if name == TARGET_METHOD:
                in_start_request.append((seen_try, hit))
            elif seen_try:
                in_try_anywhere.append(hit)

    for seen_try, hit in in_start_request:
        if seen_try:
            return hit
    if in_start_request:
        return in_start_request[0][1]
    if in_try_anywhere:
        return in_try_anywhere[0]
    return None


def patch(path):
    with open(path, "r", encoding="utf-8", errors="surrogateescape") as handle:
        lines = handle.read().split("\n")

    if any(HOOK_CLASS in line for line in lines):
        print("  Already patched: %s" % path)
        return True

    point = pick_injection_point(lines)
    if point is None:
        print("  Error: no java.net.URI field load found in %s" % path)
        print("  Instagram may have restructured TigonServiceLayer; the hook")
        print("  needs a new injection point before this version can be patched.")
        return False

    index, register = point
    # invoke-static/range takes any register number; the plain form is limited
    # to v0-v15 and would fail to assemble on a high register.
    hook = [
        "",
        "    # InstaFree: drop requests for blocked surfaces",
        "    invoke-static/range {%s .. %s}, %s->%s" % (register, register, HOOK_CLASS, HOOK_METHOD),
        "",
    ]
    lines[index + 1 : index + 1] = hook

    with open(path, "w", encoding="utf-8", errors="surrogateescape") as handle:
        handle.write("\n".join(lines))

    print("  Patched: %s" % path)
    print("  Hook inserted after: %s" % lines[index].strip())
    return True


def main(argv):
    if len(argv) != 2:
        print(__doc__)
        return 2

    target = find_tigon(argv[1])
    if target is None:
        print("  Error: TigonServiceLayer.smali not found under %s" % argv[1])
        return 1

    return 0 if patch(target) else 1


if __name__ == "__main__":
    sys.exit(main(sys.argv))
