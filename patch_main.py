import sys

def patch_main_activity(file_path):
    with open(file_path, 'r') as f:
        content = f.read()

    # In InstagramMainActivity, pswitch_1 is for Reels.
    # We change it to load fragment_direct_tab instead of fragment_clips.
    old_code = ':pswitch_1\n    const-string/jumbo v2, "fragment_clips"'
    new_code = ':pswitch_1\n    const-string/jumbo v2, "fragment_direct_tab"'

    if old_code in content:
        new_content = content.replace(old_code, new_code)
        with open(file_path, 'w') as f:
            f.write(new_content)
        print(f"Successfully patched {file_path}")
    elif 'fragment_direct_tab' in content and ':pswitch_1' in content:
         print(f"Already patched or manually verified in {file_path}")
    else:
        print(f"Could not find patch point in {file_path}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)
    patch_main_activity(sys.argv[1])