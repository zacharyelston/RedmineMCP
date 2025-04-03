#!/usr/bin/env python3
"""
Script to update items in Redmine based on YAML templates.
Usage: python update_redmine_item.py <template_name> [param1=value1 param2=value2 ...] [output_file]
"""

import sys
import os
import yaml
from redmine_utils import load_template, make_request, save_response

def update_redmine_item(template_name, params_override=None, output_file=None):
    """Update Redmine item based on template configuration"""
    template = load_template(template_name)
    
    # Extract request details from template
    endpoint = template.get('endpoint')
    method = template.get('method', 'PUT')
    data = template.get('data', {})
    item_id = template.get('item_id')
    
    if not endpoint:
        print("Endpoint must be specified in the template")
        sys.exit(1)
    
    # Check if item_id is in the template or needs to be provided
    if '{item_id}' in endpoint and (not item_id and not (params_override and 'item_id' in params_override)):
        print("Item ID must be specified in the template or as a parameter")
        sys.exit(1)
    
    # Override template parameters with command line arguments
    if params_override:
        # Handle item_id in endpoint
        if 'item_id' in params_override:
            item_id = params_override['item_id']
            # Remove from params_override to avoid adding to data
            del params_override['item_id']
        
        # Handle nested structures in data
        for key, value in params_override.items():
            keys = key.split('.')
            target = data
            for k in keys[:-1]:
                if k not in target:
                    target[k] = {}
                target = target[k]
            target[keys[-1]] = value
    
    # Replace item_id in endpoint if needed
    if '{item_id}' in endpoint:
        endpoint = endpoint.replace('{item_id}', str(item_id))
    
    # Make the request
    print(f"Updating {template.get('description', 'item')} in Redmine...")
    response = make_request(method, endpoint, data=data)
    
    # Save or print the response
    save_response(response, output_file)
    
    return response

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python update_redmine_item.py <template_name> [param1=value1 param2=value2 ...] [output_file]")
        sys.exit(1)
    
    template_name = sys.argv[1]
    
    # Check if last argument is the output file
    last_arg = sys.argv[-1]
    if len(sys.argv) > 2 and not "=" in last_arg:
        output_file = last_arg
        param_args = sys.argv[2:-1]
    else:
        output_file = None
        param_args = sys.argv[2:]
    
    # Parse parameter overrides from command line
    params_override = {}
    for arg in param_args:
        if "=" in arg:
            key, value = arg.split("=", 1)
            
            # Try to detect and convert values to appropriate types
            if value.lower() == 'true':
                value = True
            elif value.lower() == 'false':
                value = False
            elif value.isdigit():
                value = int(value)
            
            params_override[key] = value
    
    update_redmine_item(template_name, params_override, output_file)
