import os
import glob
import re

modules_path = r'd:\MadOS_ROG\MadOS_ROG_V2\MadROG poste install\modules\*.sh'
modules = glob.glob(modules_path)

color_lines = [
    r"RED='\\033\[0;31m'\r.*?\n|RED='\\033\[0;31m'\n",
    r"WHITE='\\033\[1;37m'\r.*?\n|WHITE='\\033\[1;37m'\n",
    r"GRAY='\\033\[0;90m'\r.*?\n|GRAY='\\033\[0;90m'\n",
    r"NC='\\033\[0m'\r.*?\n|NC='\\033\[0m'\n",
    r"# ---- Couleurs & Styles ----\r.*?\n|# ---- Couleurs & Styles ----\n"
]

def process_file(filepath):
    print(f"Processing {filepath}")
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original_content = content
    
    # 1. Remove color block lines
    for line_regex in color_lines:
        content = re.sub(line_regex, '', content)

    # 2. Add empty lines cleanup if multiple consecutive empty lines are left
    content = re.sub(r'\n{3,}', '\n\n', content)

    # 3. Standardize success output ✅
    # Replace anything like "✅ XXX" with "✅ [SUCCÈS] XXX"
    content = re.sub(r'✅(?! \[SUCCÈS\])', '✅ [SUCCÈS]', content)
    
    # Standardize error output ❌
    content = re.sub(r'❌(?! \[ERREUR\])', '❌ [ERREUR]', content)

    # Standardize warning output ⚠️
    content = re.sub(r'⚠️(?! \[ATTENTION\])', '⚠️  [ATTENTION]', content)
    # Some might be "⚠️  " which becomes "⚠️  [ATTENTION]  ". Let's clean double spaces after bracket.
    content = content.replace('⚠️  [ATTENTION]  ', '⚠️  [ATTENTION] ')

    if original_content != content:
        with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
            f.write(content)

for mod in modules:
    process_file(mod)

print("Done formatting scripts.")
