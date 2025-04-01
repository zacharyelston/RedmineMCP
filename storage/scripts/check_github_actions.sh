#!/bin/bash
# Script to check the GitHub Actions workflow files for errors

set -e

echo "Checking GitHub Actions workflow files..."

# Define the workflows directory
WORKFLOWS_DIR=".github/workflows"

# Create the directory if it doesn't exist
if [ ! -d "$WORKFLOWS_DIR" ]; then
    echo "Creating workflows directory..."
    mkdir -p "$WORKFLOWS_DIR"
    echo "Created $WORKFLOWS_DIR"
fi

# Check if any workflow files exist
WORKFLOW_FILES=$(find $WORKFLOWS_DIR -name "*.yml" -o -name "*.yaml")
if [ -z "$WORKFLOW_FILES" ]; then
    echo "No workflow files found in $WORKFLOWS_DIR"
    exit 0
fi

# Check each workflow file for basic YAML syntax
echo "Checking YAML syntax for workflow files..."
for FILE in $WORKFLOW_FILES; do
    echo "Checking $FILE..."
    if command -v yamllint &> /dev/null; then
        # If yamllint is available, use it for more thorough checking
        yamllint -c .yamllint.yml "$FILE" || echo "WARNING: YAML lint errors found in $FILE"
    else
        # Otherwise, use basic yaml parsing in Python
        python3 -c "import yaml; yaml.safe_load(open('$FILE', 'r'))" || {
            echo "ERROR: Invalid YAML syntax in $FILE"
            exit 1
        }
    fi
done

# Check GitHub Actions specific patterns
echo "Checking GitHub Actions specific patterns..."

# Common issues to check:
# 1. Missing 'on:' section
# 2. Jobs without 'runs-on:' specified
# 3. Invalid Docker image references
# 4. Missing main keys like 'jobs:'
for FILE in $WORKFLOW_FILES; do
    echo "Checking Actions patterns in $FILE..."
    
    # Simple grep checks
    if ! grep -q "^on:" "$FILE"; then
        echo "WARNING: Missing 'on:' trigger in $FILE"
    fi
    
    if ! grep -q "^jobs:" "$FILE"; then
        echo "WARNING: Missing 'jobs:' section in $FILE"
    fi
    
    # Check that each job has 'runs-on:' unless it uses container
    JOB_NAMES=$(grep -E "^  [a-zA-Z0-9_.-]+:" "$FILE" | sed 's/://')
    for JOB in $JOB_NAMES; do
        # Skip lines that don't look like job names
        [[ "$JOB" =~ ^(on|name|defaults|env|jobs|permissions)$ ]] && continue
        
        JOB_CONTENT=$(sed -n "/^  $JOB:/,/^  [a-zA-Z0-9_.-]:/p" "$FILE")
        
        if ! echo "$JOB_CONTENT" | grep -q "runs-on:" && ! echo "$JOB_CONTENT" | grep -q "container:"; then
            echo "WARNING: Job '$JOB' in $FILE missing either 'runs-on:' or 'container:'"
        fi
    done
done

echo "Workflow file checks completed"