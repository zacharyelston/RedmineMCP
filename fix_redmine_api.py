#!/usr/bin/env python3
"""Fix redmine_api.py type issues"""

import re

with open('redmine_api.py', 'r') as f:
    content = f.read()

# Fix all instances of include parameter handling with type conversion
fixed_content = re.sub(
    r'params\["include"\] = include',
    r'params["include"] = str(include)',
    content
)

with open('redmine_api.py', 'w') as f:
    f.write(fixed_content)

print("Fixed redmine_api.py include parameter type issues")
