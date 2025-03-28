#!/bin/bash
# Script to create a new feature branch for Redmine MCP Extension development

# Check if git is available
if ! command -v git &> /dev/null; then
    echo "Error: git is not installed or not available in PATH"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --is-inside-work-tree &> /dev/null; then
    echo "Error: Not inside a git repository"
    exit 1
fi

# Check if there are uncommitted changes
if ! git diff-index --quiet HEAD --; then
    echo "Warning: You have uncommitted changes"
    echo "It's recommended to commit or stash your changes before creating a new branch"
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 0
    fi
fi

# Prompt for branch name
read -p "Enter a name for the new feature branch (e.g., add-new-endpoint): " branch_name

# Validate branch name
if [[ -z "$branch_name" ]]; then
    echo "Error: Branch name cannot be empty"
    exit 1
fi

# Clean the branch name (replace spaces with hyphens, remove special characters)
clean_branch_name=$(echo "$branch_name" | tr ' ' '-' | tr -cd 'a-zA-Z0-9-_')

# Create the feature branch name with a prefix
feature_branch="feature/${clean_branch_name}"

# Check if branch already exists
if git show-ref --verify --quiet "refs/heads/$feature_branch"; then
    echo "Error: Branch '$feature_branch' already exists"
    exit 1
fi

# Make sure we're on main branch and up to date
echo "Switching to main branch and pulling latest changes..."
git checkout main
git pull

# Create the new branch
echo "Creating new branch: $feature_branch"
git checkout -b "$feature_branch"

if [ $? -eq 0 ]; then
    echo "✅ Successfully created branch $feature_branch"
    echo "You can now make your changes and commit them to this branch."
    echo "When finished, create a pull request to merge your changes into main."
else
    echo "❌ Error creating branch"
    exit 1
fi