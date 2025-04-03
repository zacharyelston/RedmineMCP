#!/usr/bin/env python3
"""
Script to get items from Redmine based on YAML templates.
Usage: python get_redmine_item.py <template_name> [output_file]
"""

import sys
import os
from redmine_utils import load_template, make_request, save_response

def get_redmine_item(template_name, output_file=None):
    """Get Redmine item based on template configuration"""
    template = load_template(template_name)
    
    # Extract request details from template
    endpoint = template.get('endpoint')
    method = template.get('method', 'GET')
    params = template.get('params', {})
    
    if not endpoint:
        print("Endpoint must be specified in the template")
        sys.exit(1)
    
    # Make the request
    print(f"Retrieving {template.get('description', 'item')} from Redmine...")
    response = make_request(method, endpoint, params=params)
    
    # Save or print the response
    save_response(response, output_file)
    
    return response

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python get_redmine_item.py <template_name> [output_file]")
        sys.exit(1)
    
    template_name = sys.argv[1]
    output_file = sys.argv[2] if len(sys.argv) > 2 else None
    
    get_redmine_item(template_name, output_file)
