#!/bin/bash

# Script to create a new feature branch using a consistent naming convention

# Check if feature name is provided
if [ $# -eq 0 ]; then
    echo "Error: Feature name is required"
    echo "Usage: $0 <feature-name>"
    exit 1
fi

# Normalize feature name (convert spaces to hyphens, lowercase)
FEATURE_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

# Create a branch name with feature/ prefix and current date
BRANCH_NAME="feature/${FEATURE_NAME}-$(date +%Y%m%d)"

# Check if git is initialized
if [ ! -d ".git" ]; then
    echo "Initializing git repository..."
    git init
    git add .
    git commit -m "Initial commit"
fi

# Create and checkout the new branch
echo "Creating branch: $BRANCH_NAME"
git checkout -b "$BRANCH_NAME"

# Success message
echo "Success! Now working on branch: $BRANCH_NAME"
echo "When you're ready to commit your changes, use:"
echo "git add ."
echo "git commit -m \"feat: your descriptive message here\""