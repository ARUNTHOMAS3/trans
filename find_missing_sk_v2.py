import os
import re

def find_skeletonizers_without_ignore_containers(root_dir):
    results = []
    skeletonizer_pattern = re.compile(r'Skeletonizer\s*\(')
    ignore_containers_pattern = re.compile(r'ignoreContainers\s*:\s*true')
    
    for root, dirs, files in os.walk(root_dir):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                try:
                    with open(file_path, 'r', encoding='utf-8') as f:
                        content = f.read()
                        
                        # Find all occurrences of Skeletonizer
                        start_pos = 0
                        while True:
                            match = skeletonizer_pattern.search(content, start_pos)
                            if not match:
                                break
                                
                            start = match.start()
                            # We need to find the matching closing bracket or a reasonable range
                            # to check for properties of this specific Skeletonizer call.
                            # Let's check the next 512 characters.
                            context = content[start:start+512]
                            
                            # Simple check: does this context contain ignoreContainers: true?
                            if not ignore_containers_pattern.search(context):
                                # Double check that we didn't just find a match in a comment
                                # (basic check for //)
                                line_start = content.rfind('\n', 0, start) + 1
                                line_content = content[line_start:content.find('\n', start)]
                                if '//' not in line_content.split('Skeletonizer')[0]:
                                    line_no = content.count('\n', 0, start) + 1
                                    results.append(f"{file_path}:{line_no}")
                            
                            start_pos = match.end()
                except Exception as e:
                    print(f"Error reading {file_path}: {e}")
    return results

if __name__ == "__main__":
    # Check lib directory
    found = find_skeletonizers_without_ignore_containers('e:/zerpai-new/lib')
    if not found:
        print("SUCCESS: All Skeletonizer instances have ignoreContainers: true")
    else:
        for item in found:
            print(item)
