import sys
import os

def patch_smali(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    old_marker = 'check-cast v7, Ljava/lang/String;'
    
    if old_marker not in content:
        print(f"Could not find {old_marker} in {file_path}")
        return

    # Redirection logic:
    # if (v7.equals("fragment_clips")) { v7 = "fragment_direct_tab"; }
    # In smali:
    # if-eqz v0, :not_reels  # if v0 is zero (NOT equals), skip to :not_reels
    patch = '''
    # Feurstagram: Redirect Reels to DMs
    const-string/jumbo v0, "fragment_clips"
    invoke-virtual {v7, v0}, Ljava/lang/String;->equals(Ljava/lang/Object;)Z
    move-result v0
    if-eqz v0, :not_reels
    const-string/jumbo v7, "fragment_direct_tab"
    :not_reels
'''
    
    # We need to make sure we dont double patch if we run multiple times
    if '# Feurstagram' in content:
        print(f"Already patched {file_path}")
        return

    new_content = content.replace(old_marker, old_marker + patch)
    
    with open(file_path, 'w') as f:
        f.write(new_content)
    print(f"Successfully patched {file_path}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)
    patch_smali(sys.argv[1])
