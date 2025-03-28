from datetime import datetime
from app import db

class Config(db.Model):
    """
    Stores configuration settings for the application
    """
    id = db.Column(db.Integer, primary_key=True)
    redmine_url = db.Column(db.String(256), nullable=False)
    redmine_api_key = db.Column(db.String(256), nullable=False)
    openai_api_key = db.Column(db.String(256), nullable=False)
    rate_limit_per_minute = db.Column(db.Integer, default=60)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class ActionLog(db.Model):
    """
    Logs all actions performed by the LLM
    """
    id = db.Column(db.Integer, primary_key=True)
    action_type = db.Column(db.String(64), nullable=False)  # create, update, etc.
    issue_id = db.Column(db.Integer, nullable=True)  # Nullable for actions that don't target a specific issue
    content = db.Column(db.Text, nullable=False)  # What was done
    prompt = db.Column(db.Text, nullable=False)  # The prompt that was sent to the LLM
    response = db.Column(db.Text, nullable=False)  # The response from the LLM
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    success = db.Column(db.Boolean, default=True)
    error_message = db.Column(db.Text, nullable=True)

class PromptTemplate(db.Model):
    """
    Stores templates for common LLM prompts
    """
    id = db.Column(db.Integer, primary_key=True)
    name = db.Column(db.String(128), nullable=False)
    description = db.Column(db.Text, nullable=True)
    template = db.Column(db.Text, nullable=False)
    created_at = db.Column(db.DateTime, default=datetime.utcnow)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

class RateLimitTracker(db.Model):
    """
    Tracks API calls for rate limiting purposes
    """
    id = db.Column(db.Integer, primary_key=True)
    api_name = db.Column(db.String(64), nullable=False)  # 'redmine' or 'openai'
    count = db.Column(db.Integer, default=0)
    reset_at = db.Column(db.DateTime, nullable=False)  # When the counter resets
