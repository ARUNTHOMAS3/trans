import re
import sys

def main():
    log_file = 'flutter_analyze.log'
    with open(log_file, 'r', encoding='utf-16') as f:
        lines = f.readlines()
        
    files_to_fix = {}
    
    for line in lines:
        if 'override_on_non_overriding_member' in line:
            match = re.search(r' - (lib[^\:]+):(\d+):(\d+)', line)
            if match:
                file_path = match.group(1)
                line_num = int(match.group(2))
                
                if file_path not in files_to_fix:
                    files_to_fix[file_path] = []
                files_to_fix[file_path].append(line_num)
                
    for file_path, line_nums in files_to_fix.items():
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.readlines()
                
            for ln in sorted(line_nums, reverse=True):
                idx = ln - 1
                if 0 <= idx < len(content):
                    if '@override' in content[idx]:
                        content[idx] = content[idx].replace('@override', '')
                        
            with open(file_path, 'w', encoding='utf-8') as f:
                f.writelines(content)
            print(f'Fixed overrides in {file_path}')
        except Exception as e:
            print(f'Error fixing {file_path}: {e}')

if __name__ == '__main__':
    main()
