"""
Test utilities for the Redmine MCP extension
"""
import os
import tempfile
import yaml
from contextlib import contextmanager

import pytest
from app import app, db
from models import Config

from tests.config import (
    TEST_REDMINE_URL, 
    TEST_REDMINE_API_KEY, 
    TEST_CLAUDE_API_KEY
)


@pytest.fixture
def client():
    """Create a test client for the Flask app"""
    app.config['TESTING'] = True
    app.config['WTF_CSRF_ENABLED'] = False
    
    # Use an in-memory database for testing
    app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///:memory:'
    
    with app.test_client() as client:
        with app.app_context():
            db.create_all()
            yield client
            db.drop_all()


@pytest.fixture
def config_db():
    """Create a test config in the database"""
    config = Config(
        redmine_url=TEST_REDMINE_URL,
        redmine_api_key=TEST_REDMINE_API_KEY,
        claude_api_key=TEST_CLAUDE_API_KEY,
        rate_limit_per_minute=60
    )
    db.session.add(config)
    db.session.commit()
    return config


@contextmanager
def temp_credentials_file():
    """
    Create a temporary credentials.yaml file for testing
    
    Usage:
        with temp_credentials_file() as temp_file:
            # Test code that uses credentials.yaml
    """
    credentials = {
        'redmine_url': TEST_REDMINE_URL,
        'redmine_api_key': TEST_REDMINE_API_KEY,
        'claude_api_key': TEST_CLAUDE_API_KEY,
        'rate_limit_per_minute': 60
    }
    
    temp_dir = tempfile.gettempdir()
    temp_path = os.path.join(temp_dir, 'credentials.yaml')
    
    try:
        # Create the temporary file
        with open(temp_path, 'w') as f:
            yaml.dump(credentials, f)
        
        # Save the current directory
        original_dir = os.getcwd()
        
        try:
            # Change to the temp directory
            os.chdir(temp_dir)
            yield temp_path
        finally:
            # Return to the original directory
            os.chdir(original_dir)
    finally:
        # Clean up the temporary file
        if os.path.exists(temp_path):
            os.remove(temp_path)