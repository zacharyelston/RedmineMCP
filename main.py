from app import app
from utils import update_config_from_credentials
from mcp import register_mcp
from routes import register_routes
import logging
from migrations import migrate_config_table

# Set up logging
logging.basicConfig(level=logging.DEBUG)
logger = logging.getLogger(__name__)

# Initialize application when it starts
with app.app_context():
    # Run database migrations
    migration_success, migration_message = migrate_config_table()
    logger.info(f"Database migrations: {migration_message}")
    
    # Try to load configuration from credentials.yaml
    success, message = update_config_from_credentials()
    logger.info(f"Loading credentials: {message}")
    
    # Register routes and MCP functionality
    register_routes(app)
    logger.info("Main routes registered")
    
    register_mcp(app)
    logger.info("MCP integration registered")

if __name__ == "__main__":
    logger.info("Starting Redmine MCP Extension on port 9000")
    app.run(host="0.0.0.0", port=9000, debug=True)
