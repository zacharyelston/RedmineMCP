"""
Main application setup for the Redmine MCP Extension.
File-based configuration replaces database dependency.
"""

import os
import logging
from flask import Flask

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Create Flask application
app = Flask(__name__)

# Configure secret key for Flask session
app.secret_key = os.environ.get("SESSION_SECRET", "dev-secret-key")

logger.info("Flask application initialized")

# Import configuration module (but don't use it yet)
# This is imported here to avoid circular imports
import config

logger.info("Configuration module loaded")