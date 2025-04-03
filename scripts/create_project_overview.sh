#!/bin/bash
# Script to create or update the ProjectOverview wiki page
# Usage: ./create_project_overview.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/create_item.sh" project_overview_wiki

echo "ProjectOverview wiki page created/updated. View at: http://localhost:3000/projects/redminemcp/wiki/ProjectOverview"
