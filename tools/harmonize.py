import os
import re

TARGET_DIR = r"D:\MadOS_ROG\MadOS_ROG_V2\MadROG poste install"

COLOR_VARS = """# ==============================================================================
# Variables de Couleurs pour UI Terminal
# ==============================================================================
RED='\\033[0;31m'
GREEN='\\033[0;32m'
CYAN='\\033[0;36m'
WHITE='\\033[1;37m'
GRAY='\\033[0;37m'
YELLOW='\\033[0;33m'
BOLD='\\033[1m'
NC='\\033[0m'
"""

def update_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    filename = os.path.basename(filepath)
    is_module = 'modules' in filepath and filename.endswith('.sh')

    lines = content.split('\n')
    cleaned_lines = []
    in_header = True
    desc_lines = []
    
    for line in lines:
        if in_header:
            if line.startswith('#!/bin/bash'): continue
            if line.startswith('# =='): continue
            if line.startswith('# MadOS'): continue
            if line.startswith('# Phase:') or (line.startswith('#') and len(line) > 1 and 'MadOS' not in line):
                desc_lines.append(line.strip())
                continue
            if line.strip() == '': continue
            in_header = False
            
        if not in_header:
            if re.match(r'^(RED|GREEN|CYAN|WHITE|GRAY|YELLOW|BOLD|NC)=', line.strip()) or 'export BOLD' in line or 'export YELLOW' in line:
                continue
            cleaned_lines.append(line)

    new_header = f"#!/bin/bash\n"
    new_header += f"# {'=' * 78}\n"
    new_header += f"# MadOS ROG Edition 3.0 - {filename}\n"
    new_header += f"# {'=' * 78}\n"
    for d in desc_lines:
        new_header += f"{d}\n"
    if desc_lines:
        new_header += f"# {'=' * 78}\n"

    new_content = new_header + "\n"
    if is_module or filename in ["install.sh", "install_local.sh"]:
        new_content += COLOR_VARS + "\n"
        
    main_body = '\n'.join(cleaned_lines)
    
    # 1. Clean Success Messages
    # Ex: echo -e "    ${WHITE}✅ [SUCCÈS] Phase 0 Terminée.${NC}"
    # Will match ✅ and then [SUCCÈS] and then anything up to a quote
    main_body = re.sub(r'echo\s+-e\s+["\'].*?✅.*?\[SUCCÈS\]?.*?(Phase\s*\d+\s*.*?)["\'].*',
                       r'echo -e "    ${WHITE}✅ [SUCCÈS] \1${NC}"', main_body, flags=re.IGNORECASE)
    
    # Some don't have [SUCCÈS], just ✅
    main_body = re.sub(r'echo\s+-e\s+["\'].*?✅\s*(Phase\s*\d+\s*.*?)["\'].*',
                       r'echo -e "    ${WHITE}✅ [SUCCÈS] \1${NC}"', main_body, flags=re.IGNORECASE)

    # Clean double NC tags due to regex 
    main_body = main_body.replace('${NC}${NC}', '${NC}')


    # 2. Standardize Title Box
    if is_module:
        title_match = re.search(r'echo\s+-e\s+"(?:\\n)?.*?(?:>>>|╔).*?(Phase\s*\d+|Déploiement|Injection|Purification|Application|Configuration|Mise).*?"', main_body, re.IGNORECASE)
        if title_match:
            raw_title = title_match.group(0)
            
            title_text = re.sub(r'echo\s+-e\s+"(?:\\n)?', '', raw_title)
            title_text = re.sub(r'\${[A-Z]+}', '', title_text)
            title_text = title_text.replace('>>>', '').replace('╔', '').replace(']', '').replace('[', '').replace('...', '').replace('"', '').replace('═','').replace('║','').replace('╚','').replace('╝','').replace('🚀','').strip()
            title_text = re.sub(r'\s+', ' ', title_text)

            box_code = f"""echo -e "\\n${{RED}}╔{'═'*74}╗${{NC}}"
echo -e "${{RED}}║${{NC}} 🚀 ${{WHITE}}${{BOLD}}{title_text}${{NC}}"
echo -e "${{RED}}╚{'═'*74}╝${{NC}}\\n\""""
            
            if '╔' in raw_title or '╚' in raw_title:
                box_match = re.search(r'echo\s+-e\s+"(?:\\n)?.*?(>>>|╔)(.*?)╚.*?\\n"', main_body, re.DOTALL)
                if box_match:
                    main_body = main_body[:box_match.start()] + box_code + main_body[box_match.end():]
                else:
                    main_body = main_body.replace(raw_title, box_code)
            else:
                main_body = main_body.replace(raw_title, box_code)

    # 3. Fix List padding
    main_body = re.sub(r'echo\s+-e\s+"(?:\\n)?(\s*├─)', r'echo -e "    ${GRAY}\1', main_body)
    main_body = main_body.replace('${GRAY}    ${GRAY}', '${GRAY}    ')
    main_body = main_body.replace('${GRAY}    ${WHITE}', '    ${WHITE}')

    new_content += main_body

    with open(filepath, 'w', encoding='utf-8', newline='\n') as f:
        f.write(new_content)

for root, _, files in os.walk(TARGET_DIR):
    for f in files:
        if f.endswith('.sh'):
            update_file(os.path.join(root, f))
print("Done")
