#!/usr/bin/env python3
"""
Fix all redmine_api.py include parameter issues
This script replaces the direct dictionary assignments with the update method
"""
import re
import os

file_path = 'redmine_api.py'

# Read the content of the file
with open(file_path, 'r') as file:
    content = file.read()

# Pattern to match the include parameter handling
pattern = r'(\s+if include:.*?\s+if isinstance\(include, list\):.*?\s+)params\["include"\] = ",".join\(include\)(.*?\s+else:.*?\s+)params\["include"\] = str\(include\)'
replacement = r'\1include_str = ",".join(include)\n        params.update({"include": include_str})\2include_str = str(include)\n        params.update({"include": include_str})'

# Apply the pattern replacement using re.DOTALL to match across newlines
modified_content = re.sub(pattern, replacement, content, flags=re.DOTALL)

# Write the modified content back to the file
with open(file_path, 'w') as file:
    file.write(modified_content)

print("Successfully updated all include parameter handling in redmine_api.py")