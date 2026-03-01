import os

files = ['Menu_Installation_ROG.sh', 'modules/14_openclaw_ai.sh', 'modules/format_scripts.py']

for f in files:
    if os.path.exists(f):
        with open(f, 'rb') as file:
            content = file.read().replace(b'\r\n', b'\n')
        with open(f, 'wb') as file:
            file.write(content)
        print(f"Fixed LF for {f}")
