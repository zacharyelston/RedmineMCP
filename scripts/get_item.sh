#!/bin/bash
# Wrapper script for getting items from Redmine
# Usage: ./get_item.sh <template_name> [output_file]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
python3 "$SCRIPT_DIR/get_redmine_item.py" "$@"
