#!/bin/bash
# Script to create and switch to a feature branch

set -e

if [ -z "$1" ]; then
    echo "ERROR: Missing feature name."
    echo "Usage: $0 <feature-name>"
    echo "Example: $0 add-claude-integration"
    exit 1
fi

# Get the feature name
FEATURE_NAME="$1"

# Add feature/ prefix if not present
if [[ ! $FEATURE_NAME == feature/* ]]; then
    FEATURE_NAME="feature/$FEATURE_NAME"
fi

# Check if git repo exists
if [ ! -d .git ]; then
    echo "ERROR: Not a git repository. Please run this script from the root of the git repository."
    exit 1
fi

# Get the current branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD)

# Check if we're already on the feature branch
if [ "$CURRENT_BRANCH" = "$FEATURE_NAME" ]; then
    echo "Already on branch '$FEATURE_NAME'."
    exit 0
fi

# Check if the branch already exists
if git rev-parse --verify --quiet "$FEATURE_NAME" >/dev/null; then
    echo "Branch '$FEATURE_NAME' already exists. Switching to it..."
    git checkout "$FEATURE_NAME"
else
    echo "Creating new branch '$FEATURE_NAME' from '$CURRENT_BRANCH'..."
    git checkout -b "$FEATURE_NAME"
fi

echo "Success! You are now on branch '$FEATURE_NAME'."