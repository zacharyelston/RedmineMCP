"""
Database migrations for the Redmine MCP Extension.
"""

import logging
from sqlalchemy import text
from app import db, app

logger = logging.getLogger(__name__)

def migrate_config_table():
    """
    Migrate the config table to add mcp_url column and make claude_api_key nullable
    """
    logger.info("Running database migrations...")
    
    with app.app_context():
        try:
            # Check if the mcp_url column already exists
            result = db.session.execute(text("SELECT column_name FROM information_schema.columns WHERE table_name='config' AND column_name='mcp_url'"))
            column_exists = result.scalar() is not None
            
            if not column_exists:
                logger.info("Adding mcp_url column to config table")
                db.session.execute(text("ALTER TABLE config ADD COLUMN mcp_url VARCHAR(256)"))
                db.session.commit()
                logger.info("Added mcp_url column successfully")
            else:
                logger.info("mcp_url column already exists")
            
            # Make claude_api_key nullable for backward compatibility
            db.session.execute(text("ALTER TABLE config ALTER COLUMN claude_api_key DROP NOT NULL"))
            db.session.commit()
            logger.info("Made claude_api_key column nullable")
            
            # Update default llm_provider value
            db.session.execute(text("UPDATE config SET llm_provider = 'claude-desktop' WHERE id = 1"))
            db.session.commit()
            logger.info("Updated llm_provider value to claude-desktop")
            
            # The MCP port is now fully configurable and should not be enforced
            # We no longer migrate from port 5001 to 5000 as different environments may need different ports
            logger.info("MCP URL port is fully configurable - no port migration needed")
            
            return True, "Database migrations completed successfully"
        except Exception as e:
            logger.error(f"Error during migrations: {str(e)}")
            db.session.rollback()
            return False, f"Migration error: {str(e)}"

if __name__ == "__main__":
    success, message = migrate_config_table()
    
    if success:
        logger.info(message)
    else:
        logger.error(message)