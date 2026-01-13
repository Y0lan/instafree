import os
import sys

def global_redirect(directory):
    target = '"fragment_clips"'
    replacement = '"fragment_direct_tab"'
    count = 0
    for root, dirs, files in os.walk(directory):
        for file in files:
            if file.endswith(".smali"):
                path = os.path.join(root, file)
                with open(path, 'r') as f:
                    content = f.read()
                if target in content:
                    new_content = content.replace(target, replacement)
                    with open(path, 'w') as f:
                        f.write(new_content)
                    count += 1
    print(f"Patched {count} files with global redirection.")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        sys.exit(1)
    global_redirect(sys.argv[1])
