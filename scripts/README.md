# Redmine Integration Scripts

This directory contains scripts for interacting with the Redmine API in a controlled, repeatable way using YAML templates. The scripts emphasize process over implementation by separating the code that makes API calls from the data being sent or retrieved.

## Key Principles

1. **Separation of Concerns**: Scripts handle the mechanics of API calls while YAML templates define what to send/retrieve
2. **Process-Oriented**: Standardized processes for common operations with Redmine
3. **Security Through Repetition**: Defined patterns for API interaction reduce risk of errors
4. **Flexibility**: YAML templates can be easily modified without changing scripts

## Scripts

All scripts can be run using the shell wrapper or directly with Python:

### Get Items

```bash
# Using shell wrapper
./get_item.sh get_project_issues [output_file.json]

# Direct Python call
python3 get_redmine_item.py get_project_issues [output_file.json]
```

### Create Items

```bash
# Using shell wrapper
./create_item.sh create_issue issue.subject="New Bug" issue.description="Found a problem" [output_file.json]

# Direct Python call
python3 create_redmine_item.py create_issue issue.subject="New Bug" issue.description="Found a problem" [output_file.json]
```

### Update Items

```bash
# Using shell wrapper
./update_item.sh update_issue item_id=123 issue.status_id=2 [output_file.json]

# Direct Python call
python3 update_redmine_item.py update_issue item_id=123 issue.status_id=2 [output_file.json]
```

## Templates

Templates are stored in the `templates` directory and use YAML format. Each template defines:

1. **description**: Human-readable description of the operation
2. **method**: HTTP method (GET, POST, PUT, DELETE)
3. **endpoint**: Redmine API endpoint
4. **params**: Query parameters for GET requests
5. **data**: JSON data for POST/PUT requests
6. **item_id**: ID for individual items (optional, can be specified on command line)

### Example Templates

- **get_project_issues.yaml**: Retrieve issues for a project
- **get_issue.yaml**: Retrieve a specific issue
- **create_issue.yaml**: Create a new issue
- **update_issue.yaml**: Update an existing issue
- **create_wiki_page.yaml**: Create or update a wiki page
- **get_wiki_page.yaml**: Retrieve a wiki page

## Creating New Templates

To create a new template:

1. Copy an existing template with similar functionality
2. Modify the endpoint, method, params, and data as needed
3. Save with a descriptive name in the templates directory

Example:

```yaml
# Template for creating a new version
description: New Version
method: POST
endpoint: versions.json
data:
  version:
    project_id: 1
    name: "New Version Name"
    status: "open"
    sharing: "none"
    description: "Description of the new version"
```

## Parameter Overrides

When running scripts, you can override values in the template with command line arguments:

- Simple values: `key=value`
- Nested values: `parent.child=value`

Examples:

```bash
# Override issue subject and description
./create_item.sh create_issue issue.subject="Critical Bug" issue.description="Server is down"

# Set the assigned user and status
./update_item.sh update_issue item_id=42 issue.assigned_to_id=1 issue.status_id=2
```

## API Reference

For detailed information about the Redmine API endpoints and parameters, see:

- Local API Guide: `/projects/Desktop/projects/RedmineMCP/REDMINE_API_GUIDE.md`
- [Redmine REST API Documentation](https://www.redmine.org/projects/redmine/wiki/Rest_api)
