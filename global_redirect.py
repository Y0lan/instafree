#!/usr/bin/env python3
"""
Inject InstaFreeRedirect.resolveFragment() calls after fragment string constants.

Instead of statically replacing "fragment_clips" with "fragment_direct_tab",
this injects a runtime method call that reads the user's configured redirect
from SharedPreferences.
"""
import os
import sys
import re

REDIRECT_FRAGMENTS = ['"fragment_clips"', '"fragment_feed"']

def inject_redirect(directory):
    """Find const-string lines loading redirect-able fragments and inject
    a call to InstaFreeRedirect.resolveFragment() after each one."""
    # Pattern matches: const-string or const-string/jumbo vN, "fragment_clips"
    pattern = re.compile(
        r'([ \t]*const-string(?:/jumbo)?\s+(v\d+),\s*'
        r'("fragment_clips"|"fragment_feed")\s*\n)'
    )
    count = 0
    for root, dirs, files in os.walk(directory):
        # Skip our own injected classes
        if 'com/instafree' in root:
            continue
        for fname in files:
            if not fname.endswith('.smali'):
                continue
            path = os.path.join(root, fname)
            with open(path, 'r') as f:
                content = f.read()

            if 'InstaFreeRedirect' in content:
                continue  # already patched

            new_content = content
            for match in reversed(list(pattern.finditer(content))):
                original_line = match.group(1)
                register = match.group(2)
                indent = re.match(r'([ \t]*)', original_line).group(1)
                inject = (
                    f'{indent}invoke-static {{{register}}}, '
                    f'Lcom/instafree/InstaFreeRedirect;->'
                    f'resolveFragment(Ljava/lang/String;)'
                    f'Ljava/lang/String;\n'
                    f'{indent}move-result-object {register}\n'
                )
                insert_pos = match.end()
                new_content = (new_content[:insert_pos]
                               + inject
                               + new_content[insert_pos:])
                count += 1

            if new_content != content:
                with open(path, 'w') as f:
                    f.write(new_content)

    print(f"Injected {count} runtime redirect calls.")

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: global_redirect.py <decompiled_dir>")
        sys.exit(1)
    inject_redirect(sys.argv[1])
