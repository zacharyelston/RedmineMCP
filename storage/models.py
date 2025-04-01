"""
Database models for the Redmine MCP Extension.
This module is deprecated - configuration is now file-based.
Kept for reference only.
"""

from datetime import datetime, timedelta

# This is a stub to prevent import errors
# The actual database is no longer used
class DBStub:
    class Column:
        def __init__(self, *args, **kwargs):
            pass
    
    class Model:
        pass
    
    class Integer:
        pass
    
    class String:
        def __init__(self, *args, **kwargs):
            pass
    
    class Text:
        pass
    
    class DateTime:
        pass
    
    class Boolean:
        pass
    
    def __init__(self):
        self.session = self
        
    def add(self, *args, **kwargs):
        pass
        
    def commit(self, *args, **kwargs):
        pass

# Create a stub DB object for compatibility
db = DBStub()

class Config(db.Model):
    """
    Stores configuration settings for the application
    """
    id = db.Column(db.Integer, primary_key=True)
    redmine_url = db.Column(db.String(256), nullable=False)
    redmine_api_key = db.Column(db.String(256), nullable=False)
    mcp_url = db.Column(db.String(256), nullable=True)  # Optional MCP service URL
    claude_api_key = db.Column(db.String(256), nullable=True)  # Kept for backward compatibility but not used
    llm_provider = db.Column(db.String(64), default='claude-desktop', nullable=False)  # Now using 'claude-desktop'
    rate_limit_per_minute = db.Column(db.Integer, default=60)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def __repr__(self):
        return f'<Config id={self.id} updated_at={self.updated_at}>'

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

    def __repr__(self):
        return f'<ActionLog id={self.id} action_type={self.action_type} issue_id={self.issue_id} success={self.success}>'

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

    def __repr__(self):
        return f'<PromptTemplate id={self.id} name={self.name}>'

class RateLimitTracker(db.Model):
    """
    Tracks API calls for rate limiting purposes
    """
    id = db.Column(db.Integer, primary_key=True)
    api_name = db.Column(db.String(64), nullable=False)  # 'redmine' or 'claude'
    count = db.Column(db.Integer, default=0)
    reset_at = db.Column(db.DateTime, nullable=False)  # When the counter resets

    def __repr__(self):
        return f'<RateLimitTracker id={self.id} api_name={self.api_name} count={self.count} reset_at={self.reset_at}>'

    @classmethod
    def get_or_create(cls, api_name):
        """Get or create a rate limit tracker for the specified API"""
        tracker = cls.query.filter_by(api_name=api_name).first()
        
        now = datetime.utcnow()
        if not tracker:
            # Create a new tracker
            tracker = cls(
                api_name=api_name,
                count=0,
                reset_at=now + timedelta(minutes=1)
            )
            db.session.add(tracker)
            db.session.commit()
        elif now > tracker.reset_at:
            # Reset the counter if it's time
            tracker.count = 0
            tracker.reset_at = now + timedelta(minutes=1)
            db.session.commit()
        
        return tracker