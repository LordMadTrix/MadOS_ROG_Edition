import os

core_files = [
    r'd:\MadOS_ROG\MadOS_ROG_V2\MadROG poste install\install_local.sh',
    r'd:\MadOS_ROG\MadOS_ROG_V2\MadROG poste install\install.sh',
    r'd:\MadOS_ROG\MadOS_ROG_V2\MadROG poste install\lib\common.sh'
]

def fix_line_endings(filepath):
    if not os.path.exists(filepath):
        print(f"File not found: {filepath}")
        return
        
    print(f"Fixing line endings for {filepath}")
    with open(filepath, 'rb') as f:
        content = f.read()
    
    # Replace CRLF with LF
    new_content = content.replace(b'\r\n', b'\n')
    
    with open(filepath, 'wb') as f:
        f.write(new_content)

for f in core_files:
    fix_line_endings(f)

print("Core scripts conversion complete.")
