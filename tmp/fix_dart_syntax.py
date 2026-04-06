import os

path = r'e:\zerpai-new\lib\core\pages\settings_branches_create_page.dart'
with open(path, 'rb') as f:
    content = f.read().decode('utf-8')

# The bad code I introduced in pre-processing
old_code = """      code = f'{p1}{p2}-' + (words[2][0].toUpperCase() if words.length > 2 and words[2] else '01');
    } else {
      code = (name[:3].upper() if len(name) >= 3 else name.upper()) + '-01';"""

# Correct Dart logic
new_code = """      code = '$p1$p2-' + (words.length > 2 && words[2].isNotEmpty ? words[2][0].toUpperCase() : '01');
    } else {
      code = (name.length >= 3 ? name.substring(0, 3).toUpperCase() : name.toUpperCase()) + '-01';"""

# If the old_code has mixed \n and \r\n, this normalized find/replace will work better
content = content.replace(old_code.replace('\n', '\r\n'), new_code.replace('\n', '\r\n'))

with open(path, 'wb') as f:
    f.write(content.encode('utf-8'))
print("Successfully replaced bad code.")
