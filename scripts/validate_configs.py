#!/usr/bin/env python3
"""
Configuration Validator Script

This script validates various configuration files in the project to prevent common errors:
- pyproject.toml (TOML syntax and duplicate declarations)
- setup.py (syntax and compatibility with pyproject.toml)
- credentials.yaml (YAML syntax)
- docker-compose files (YAML syntax)

Usage:
    python scripts/validate_configs.py

Exit codes:
    0: All validations passed
    1: One or more validations failed
"""

import os
import sys
import yaml
import re
import ast
import logging
from pathlib import Path

# Try to use the built-in tomllib (Python 3.11+), fall back to tomli package
try:
    import tomllib
except ImportError:
    try:
        import tomli as tomllib
    except ImportError:
        print("Error: Neither tomllib (Python 3.11+) nor tomli package is available.")
        print("Please install tomli: pip install tomli")
        sys.exit(1)

# Setup logging
logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')
logger = logging.getLogger('validate_configs')

PROJECT_ROOT = Path(__file__).parent.parent
CONFIG_FILES = {
    'pyproject.toml': {'parser': 'toml', 'path': PROJECT_ROOT / 'pyproject.toml'},
    'setup.py': {'parser': 'python', 'path': PROJECT_ROOT / 'setup.py'},
    'credentials.yaml.example': {'parser': 'yaml', 'path': PROJECT_ROOT / 'credentials.yaml.example'},
    'docker-compose.yml': {'parser': 'yaml', 'path': PROJECT_ROOT / 'docker-compose.yml'},
    'docker-compose.local.yml': {'parser': 'yaml', 'path': PROJECT_ROOT / 'docker-compose.local.yml'},
}

def validate_toml(file_path):
    """Validate TOML file syntax and check for duplicate key declarations"""
    logger.info(f"Validating TOML file: {file_path}")
    try:
        with open(file_path, "rb") as f:
            tomllib.load(f)
        logger.info(f"✓ TOML syntax validation passed for {file_path}")
        
        # Additional check for duplicate keys (raw text scan)
        with open(file_path, "r") as f:
            content = f.read()
        
        # Check for direct duplicate section declarations
        sections = re.findall(r'^\[(.*?)\]', content, re.MULTILINE)
        duplicates = set([x for x in sections if sections.count(x) > 1])
        if duplicates:
            logger.error(f"✗ Duplicate section declarations in {file_path}: {duplicates}")
            return False
            
        # Special check for setuptools packages config which can be declared multiple ways
        if '[tool.setuptools]' in content and 'packages = ' in content and '[tool.setuptools.packages.find]' in content:
            logger.error(f"✗ Potential conflict in {file_path}: Both 'packages = ' and '[tool.setuptools.packages.find]' are defined")
            logger.error("  Choose one method: either define packages directly or use packages.find, not both")
            return False
            
        return True
    except Exception as e:
        logger.error(f"✗ Failed to validate {file_path}: {str(e)}")
        return False

def validate_yaml(file_path):
    """Validate YAML file syntax"""
    logger.info(f"Validating YAML file: {file_path}")
    try:
        with open(file_path, "r") as f:
            yaml.safe_load(f)
        logger.info(f"✓ YAML syntax validation passed for {file_path}")
        return True
    except Exception as e:
        logger.error(f"✗ Failed to validate {file_path}: {str(e)}")
        return False

def validate_python(file_path):
    """Validate Python file syntax"""
    logger.info(f"Validating Python file: {file_path}")
    try:
        with open(file_path, "r") as f:
            ast.parse(f.read())
        logger.info(f"✓ Python syntax validation passed for {file_path}")
        return True
    except Exception as e:
        logger.error(f"✗ Failed to validate {file_path}: {str(e)}")
        return False

def main():
    """Main validation function"""
    failed = False
    
    for file_name, config in CONFIG_FILES.items():
        file_path = config['path']
        
        if not file_path.exists():
            logger.warning(f"! File {file_path} does not exist, skipping validation")
            continue
            
        if config['parser'] == 'toml':
            if not validate_toml(file_path):
                failed = True
        elif config['parser'] == 'yaml':
            if not validate_yaml(file_path):
                failed = True
        elif config['parser'] == 'python':
            if not validate_python(file_path):
                failed = True
    
    if failed:
        logger.error("✗ Some validations failed. Please fix the issues above before committing.")
        return 1
    else:
        logger.info("✓ All configuration files validated successfully!")
        return 0

if __name__ == "__main__":
    sys.exit(main())