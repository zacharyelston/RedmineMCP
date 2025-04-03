#!/bin/bash
# Wrapper script for updating items in Redmine
# Usage: ./update_item.sh <template_name> [param1=value1 param2=value2 ...] [output_file]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/update_redmine_item.py" "$@"
