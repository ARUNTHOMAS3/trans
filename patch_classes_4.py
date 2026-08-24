import os
import re

def fix_nullable(directory):
    for root, _, files in os.walk(directory):
        for file in files:
            if not file.endswith('.dart'): continue
            path = os.path.join(root, file)
            try:
                with open(path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                # Replace 'double? get pickedQuantity' with 'double get pickedQuantity'
                content = re.sub(r'double\?\s+get\s+(picked|cancelled|packed|shipped|invoiced)Quantity', r'double get \1Quantity', content)
                
                # We can also add waitingPoApprovalsProvider to sales_order_list.dart
                if 'sales_order_list.dart' in file:
                    if 'awaitingPoApprovalsProvider' not in content:
                        content = "final awaitingPoApprovalsProvider = Provider((ref) => null);\n" + content
                
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(content)
            except Exception as e:
                pass

fix_nullable('lib')
