#!/bin/bash
# Wrapper script for creating items in Redmine
# Usage: ./create_item.sh <template_name> [param1=value1 param2=value2 ...] [output_file]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/create_redmine_item.py" "$@"
