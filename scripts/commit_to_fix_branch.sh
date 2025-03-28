#!/bin/bash
# Script to commit changes to a fix branch for Redmine MCP Extension

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
if git diff-index --quiet HEAD --; then
    echo "Error: No changes to commit"
    echo "Make changes before running this script"
    exit 1
fi

# Run validation script if available
if [ -f "./scripts/validate_configs.py" ]; then
    echo "Running configuration validation..."
    python ./scripts/validate_configs.py
    if [ $? -ne 0 ]; then
        echo "Validation failed. Please fix the issues before committing."
        exit 1
    fi
fi

# Prompt for branch type
echo "Select branch type:"
echo "1) fix/ - For bug fixes and corrections"
echo "2) feature/ - For new features and enhancements"
read -p "Enter choice (1/2): " branch_type_choice

case $branch_type_choice in
    1) branch_prefix="fix" ;;
    2) branch_prefix="feature" ;;
    *) echo "Invalid choice. Using 'fix' as default."; branch_prefix="fix" ;;
esac

# Prompt for branch name
read -p "Enter a name for the $branch_prefix branch (e.g., pyproject-toml-duplicate-key): " branch_name

# Validate branch name
if [[ -z "$branch_name" ]]; then
    echo "Error: Branch name cannot be empty"
    exit 1
fi

# Clean the branch name (replace spaces with hyphens, remove special characters)
clean_branch_name=$(echo "$branch_name" | tr ' ' '-' | tr -cd 'a-zA-Z0-9-_')

# Create the branch name with a prefix
new_branch="${branch_prefix}/${clean_branch_name}"

# Prompt for commit message
read -p "Enter commit message: " commit_message

if [[ -z "$commit_message" ]]; then
    echo "Error: Commit message cannot be empty"
    exit 1
fi

# Check if branch already exists
if git show-ref --verify --quiet "refs/heads/$new_branch"; then
    echo "Branch '$new_branch' already exists."
    read -p "Do you want to use this existing branch? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Operation canceled."
        exit 0
    fi
    # Switch to existing branch
    git checkout "$new_branch"
else
    # Make sure we're on main branch and up to date
    echo "Switching to main branch and pulling latest changes..."
    git checkout main
    git pull

    # Create the new branch
    echo "Creating new branch: $new_branch"
    git checkout -b "$new_branch"
fi

# Stage all changes
echo "Staging changes..."
git add .

# Commit changes
echo "Committing changes with message: $commit_message"
git commit -m "$commit_message"

if [ $? -eq 0 ]; then
    echo "✅ Successfully committed to branch $new_branch"
    echo "To push these changes to GitHub, run: git push origin $new_branch"
    echo "Then create a pull request to merge your changes into main."
else
    echo "❌ Error committing changes"
    exit 1
fi