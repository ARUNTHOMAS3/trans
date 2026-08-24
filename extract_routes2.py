import os

old_router_path = r'C:\Users\ansha\Desktop\zerpai-new-old\lib\app\routing\app_router.dart'
new_router_path = r'C:\Users\ansha\Desktop\zerpai-new\lib\app\routing\app_router.dart'

with open(old_router_path, 'r', encoding='utf-8') as f:
    old_router = f.read()

with open(new_router_path, 'r', encoding='utf-8') as f:
    new_router = f.read()

def extract_routes(content, path_str):
    idx = content.find(path_str)
    if idx == -1: return "Not found"
    
    # scan backwards a little
    start = max(0, idx - 100)
    return content[start:idx+1500]

print("OLD SALES RETURNS:")
print(extract_routes(old_router, "path: 'sales/returns'"))
print("==============================")
print("OLD CREDIT NOTES:")
print(extract_routes(old_router, "path: 'sales/credit-notes'"))
print("==============================")
print("OLD REPORTS:")
print(extract_routes(old_router, "path: '/reports'"))
