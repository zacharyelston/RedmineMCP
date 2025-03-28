#!/bin/bash

# This script creates a new feature branch for development
# Usage: ./scripts/create_feature_branch.sh feature-name

if [ -z "$1" ]; then
  echo "Error: You must provide a feature name."
  echo "Usage: ./scripts/create_feature_branch.sh feature-name"
  exit 1
fi

# Convert feature name to lowercase and replace spaces with hyphens
FEATURE_NAME=$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')

# Get current branch
CURRENT_BRANCH=$(git branch --show-current)

# Check if git is initialized
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: This directory is not a git repository."
  echo "Initialize git first with: git init"
  exit 1
fi

# Create branch name with prefix
BRANCH_NAME="feature/${FEATURE_NAME}"

# Check if branch already exists
if git show-ref --verify --quiet refs/heads/$BRANCH_NAME; then
  echo "Branch $BRANCH_NAME already exists."
  read -p "Do you want to switch to this branch? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    git checkout $BRANCH_NAME
    echo "Switched to existing branch: $BRANCH_NAME"
  else
    echo "Operation cancelled."
  fi
  exit 0
fi

# Create and switch to the new branch
git checkout -b $BRANCH_NAME

# Check if branch creation was successful
if [ $? -eq 0 ]; then
  echo "====================================="
  echo "Created and switched to new branch: $BRANCH_NAME"
  echo "Starting from: $CURRENT_BRANCH"
  echo "====================================="
  echo "When you're ready to commit your changes:"
  echo "git add ."
  echo "git commit -m \"Description of changes for $FEATURE_NAME\""
  echo "====================================="
else
  echo "Error: Failed to create branch $BRANCH_NAME"
  exit 1
fi