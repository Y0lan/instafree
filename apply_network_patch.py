#!/usr/bin/env python3
"""
Apply network blocking patch to TigonServiceLayer.

This script patches Instagram's network layer to call our InstaFreeHooks.throwIfBlocked()
method before each request, allowing us to block unwanted content.
"""

import sys
import re

def patch_tigon_service_layer(filepath):
    with open(filepath, 'r') as f:
        content = f.read()

    # Check if already patched
    if 'InstaFreeHooks' in content:
        print(f"  Already patched: {filepath}")
        return True

    # Find the pattern where URI is extracted from the request object
    # Pattern: iget-object vX, pY, LX/XXX;->AXX:Ljava/net/URI;
    # This is where the request URI is loaded before being used

    pattern = r'(iget-object\s+(v\d+),\s+p\d+,\s+LX/[^;]+;->[^:]+:Ljava/net/URI;\s*\n)'

    matches = list(re.finditer(pattern, content))

    if not matches:
        print(f"  Error: Could not find URI field access pattern in {filepath}")
        return False

    # We want to patch after the URI is loaded into a register
    # Find the one that's inside a try block (likely the main request handling)

    patched = False
    for match in matches:
        # Check if this is near a try_start
        start_pos = match.start()
        context_before = content[max(0, start_pos - 500):start_pos]

        if ':try_start' in context_before:
            uri_line = match.group(1)
            uri_reg = match.group(2)

            # Create the hook call
            hook_code = f'''
    # InstaFree: Check if this request should be blocked
    invoke-static {{{uri_reg}}}, Lcom/instafree/InstaFreeHooks;->throwIfBlocked(Ljava/net/URI;)V

'''
            # Insert the hook after the URI load
            patched_content = content.replace(uri_line, uri_line + hook_code, 1)

            with open(filepath, 'w') as f:
                f.write(patched_content)

            print(f"  Patched: {filepath}")
            print(f"  Hook inserted after: {uri_line.strip()}")
            patched = True
            break

    if not patched:
        # Fallback: patch the first occurrence
        match = matches[0]
        uri_line = match.group(1)
        uri_reg = match.group(2)

        hook_code = f'''
    # InstaFree: Check if this request should be blocked
    invoke-static {{{uri_reg}}}, Lcom/instafree/InstaFreeHooks;->throwIfBlocked(Ljava/net/URI;)V

'''
        patched_content = content.replace(uri_line, uri_line + hook_code, 1)

        with open(filepath, 'w') as f:
            f.write(patched_content)

        print(f"  Patched (fallback): {filepath}")
        patched = True

    return patched

if __name__ == '__main__':
    if len(sys.argv) != 2:
        print("Usage: apply_network_patch.py <TigonServiceLayer.smali>")
        sys.exit(1)

    if not patch_tigon_service_layer(sys.argv[1]):
        sys.exit(1)
