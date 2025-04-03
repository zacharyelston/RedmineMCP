
#!/usr/bin/env python3
import requests
import json

# Redmine API configuration
redmine_url = 'http://localhost:3000'
api_key = 'd775369e8258a39cb774c23af78de43e10452b1c'

# Create project data
project_data = {
    'project': {
        'name': 'RedmineMCP',
        'identifier': 'redminemcp',
        'description': 'A sophisticated Model Context Protocol (MCP) extension for Redmine that revolutionizes issue management through intelligent AI-driven automation and intuitive user interactions.',
        'is_public': True
    }
}

# Setup headers
headers = {
    'Content-Type': 'application/json',
    'X-Redmine-API-Key': api_key
}

# Create the project
try:
    response = requests.post(
        f'{redmine_url}/projects.json',
        headers=headers,
        data=json.dumps(project_data)
    )
    print(f"Status code: {response.status_code}")
    print(f"Response content: {response.text}")
    
    if response.status_code == 201:
        print("Project created successfully")
    else:
        print(f"Error creating project: {response.text}")
except Exception as e:
    print(f"Error creating project: {e}")
