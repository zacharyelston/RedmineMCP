#!/bin/bash
# Script to set up the CI environment for GitHub Actions

# Update pip
python -m pip install --upgrade pip

# Install tomli explicitly - required for config validation
pip install tomli>=2.0.0

# Install the package in development mode with all dependencies
pip install -e .

# Ensure all CI-specific dependencies are installed
pip install pytest responses

echo "CI environment setup complete!"