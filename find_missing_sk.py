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
                        # Find all Skeletonizer( matches
                        matches = list(skeletonizer_pattern.finditer(content))
                        for match in matches:
                            start = match.start()
                            # Look at the next 300 characters for ignoreContainers: true
                            # (usually properties are close)
                            context = content[start:start+300]
                            if not ignore_containers_pattern.search(context):
                                # Get line number
                                line_no = content.count('\n', 0, start) + 1
                                results.append(f"{file_path}:{line_no}")
                except Exception as e:
                    pass
    return results

if __name__ == "__main__":
    found = find_skeletonizers_without_ignore_containers('e:/zerpai-new/lib')
    for item in found:
        print(item)
