#!/bin/bash
# check_github_actions.sh
# Script to check GitHub Actions build results from Replit
# Usage: ./scripts/check_github_actions.sh <owner> <repo> [<workflow_name>]

set -e

# Color definitions
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if GitHub CLI is installed
if ! command -v gh &> /dev/null; then
    echo -e "${RED}GitHub CLI (gh) is not installed. Please install it first.${NC}"
    echo "For detailed installation instructions, see: ./scripts/README_GITHUB_CLI.md"
    echo "Or visit: https://cli.github.com/manual/installation"
    exit 1
fi

# Check if user is authenticated with GitHub CLI
if ! gh auth status &> /dev/null; then
    echo -e "${YELLOW}You need to authenticate with GitHub CLI first${NC}"
    echo "Run: gh auth login"
    exit 1
fi

# Check arguments
if [ "$#" -lt 2 ]; then
    echo -e "${RED}Usage: $0 <owner> <repo> [<workflow_name>]${NC}"
    echo "Example: $0 yourusername redmine-mcp-extension"
    echo "Example with workflow: $0 yourusername redmine-mcp-extension 'Claude API Test'"
    exit 1
fi

OWNER=$1
REPO=$2
WORKFLOW_NAME=$3

echo -e "${BLUE}Checking GitHub Actions workflow runs for ${OWNER}/${REPO}...${NC}"

if [ -z "$WORKFLOW_NAME" ]; then
    # List all workflow runs
    gh api repos/${OWNER}/${REPO}/actions/runs --jq '.workflow_runs[] | {name: .name, id: .id, status: .status, conclusion: .conclusion, created_at: .created_at, updated_at: .updated_at, html_url: .html_url}' | \
    jq -r 'select(.status == "completed") | "Workflow: \(.name)\nStatus: \(.status)\nResult: \(.conclusion)\nRun Date: \(.created_at)\nCompleted: \(.updated_at)\nURL: \(.html_url)\n"'
else
    # Get workflow ID first
    WORKFLOW_ID=$(gh api repos/${OWNER}/${REPO}/actions/workflows --jq '.workflows[] | select(.name == "'"$WORKFLOW_NAME"'") | .id')
    
    if [ -z "$WORKFLOW_ID" ]; then
        echo -e "${RED}Workflow '${WORKFLOW_NAME}' not found${NC}"
        echo "Available workflows:"
        gh api repos/${OWNER}/${REPO}/actions/workflows --jq '.workflows[] | .name'
        exit 1
    fi
    
    # Get runs for specific workflow
    gh api repos/${OWNER}/${REPO}/actions/workflows/${WORKFLOW_ID}/runs --jq '.workflow_runs[] | {name: .name, id: .id, status: .status, conclusion: .conclusion, created_at: .created_at, updated_at: .updated_at, html_url: .html_url}' | \
    jq -r 'select(.status == "completed") | "Workflow: \(.name)\nStatus: \(.status)\nResult: \(.conclusion)\nRun Date: \(.created_at)\nCompleted: \(.updated_at)\nURL: \(.html_url)\n"'
fi

echo -e "${GREEN}Done!${NC}"