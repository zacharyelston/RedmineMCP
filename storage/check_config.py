from app import app, db
from models import Config

with app.app_context():
    config = Config.query.first()
    if config:
        print(f"MCP URL from database: {config.mcp_url}")
        print(f"Redmine URL from database: {config.redmine_url}")
    else:
        print("No config found in database")
