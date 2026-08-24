import os
import re

old_router_path = r'C:\Users\ansha\Desktop\zerpai-new-old\lib\app\routing\app_router.dart'
new_router_path = r'C:\Users\ansha\Desktop\zerpai-new\lib\app\routing\app_router.dart'

with open(old_router_path, 'r', encoding='utf-8') as f:
    old_router = f.read()

with open(new_router_path, 'r', encoding='utf-8') as f:
    new_router = f.read()

def extract_routes(content, marker):
    # This is a very rough extraction just to print it out
    idx = content.find(marker)
    if idx == -1: return "Not found"
    
    # find the end of the GoRoute block by counting braces/parentheses
    # For simplicity, we just extract 1500 chars from the marker
    return content[idx:idx+1500]

print("OLD SALES RETURNS ROUTE:")
print(extract_routes(old_router, "// Sales - Returns"))
print("==============================")
print("OLD CREDIT NOTES ROUTE:")
print(extract_routes(old_router, "// Sales - Credit Notes"))

