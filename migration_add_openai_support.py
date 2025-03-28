"""
Migration script to add OpenAI support to the database.

This script adds the following columns to the Config table:
- openai_api_key: API key for OpenAI
- llm_provider: The LLM provider to use ('claude' or 'openai')

It also modifies:
- claude_api_key: Make this column nullable
"""

import logging
from app import app, db
from sqlalchemy import text

logger = logging.getLogger(__name__)

def run_migration():
    """Run the migration to add OpenAI support"""
    try:
        with app.app_context():
            # Add new columns
            db.session.execute(text("""
                ALTER TABLE config 
                ADD COLUMN IF NOT EXISTS openai_api_key VARCHAR(256),
                ADD COLUMN IF NOT EXISTS llm_provider VARCHAR(64) NOT NULL DEFAULT 'claude'
            """))
            
            # Make claude_api_key nullable
            db.session.execute(text("""
                ALTER TABLE config 
                ALTER COLUMN claude_api_key DROP NOT NULL
            """))
            
            db.session.commit()
            logger.info("Migration for OpenAI support completed successfully")
            return True, "Migration completed successfully"
    except Exception as e:
        logger.error(f"Migration failed: {str(e)}")
        return False, f"Migration failed: {str(e)}"

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO)
    success, message = run_migration()
    print(message)
    if not success:
        exit(1)