#!/bin/bash
# Script to create/switch to a fix branch and commit changes

set -e

# Check if at least one file and a message were provided
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "ERROR: Missing required arguments."
    echo "Usage: $0 <file-or-directory> <commit-message> [branch-name]"
    echo "Example: $0 src/models.py 'Fix user model validation' fix-user-validation"
    exit 1
fi

FILES_TO_COMMIT="$1"
COMMIT_MESSAGE="$2"
BRANCH_NAME="$3"

# If no branch name was provided, generate one from the commit message
if [ -z "$BRANCH_NAME" ]; then
    BRANCH_NAME=$(echo "$COMMIT_MESSAGE" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g' | head -c 30)
fi

# Add fix/ prefix if not present
if [[ ! $BRANCH_NAME == fix/* ]]; then
    BRANCH_NAME="fix/$BRANCH_NAME"
fi

# Check if git repo exists
if [ ! -d .git ]; then
    echo "ERROR: Not a git repository. Please run this script from the root of the git repository."
    exit 1
fi

# Get the current branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD)

# Check if we need to create/switch to a fix branch
if [ "$CURRENT_BRANCH" != "$BRANCH_NAME" ]; then
    # Check if the branch already exists
    if git rev-parse --verify --quiet "$BRANCH_NAME" >/dev/null; then
        echo "Branch '$BRANCH_NAME' already exists. Switching to it..."
        git checkout "$BRANCH_NAME"
    else
        echo "Creating new branch '$BRANCH_NAME' from '$CURRENT_BRANCH'..."
        git checkout -b "$BRANCH_NAME"
    fi
fi

# Stage the specified files/directories
echo "Staging changes in $FILES_TO_COMMIT..."
git add $FILES_TO_COMMIT

# Check if there are changes to commit
if git diff --cached --quiet; then
    echo "No changes to commit. Make sure the specified files have changes."
    exit 1
fi

# Commit the changes
echo "Committing changes with message: '$COMMIT_MESSAGE'..."
git commit -m "$COMMIT_MESSAGE"

echo "Success! Changes committed to branch '$BRANCH_NAME'."
echo "To push these changes, run: git push -u origin $BRANCH_NAME"