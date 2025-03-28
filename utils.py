from datetime import datetime, timedelta
from app import db
from models import RateLimitTracker

def is_rate_limited(api_name, rate_limit_per_minute):
    """
    Check if the API has exceeded its rate limit
    
    Args:
        api_name (str): The name of the API ('redmine' or 'openai')
        rate_limit_per_minute (int): The maximum number of calls allowed per minute
        
    Returns:
        bool: True if rate limited, False otherwise
    """
    now = datetime.utcnow()
    minute_start = now.replace(second=0, microsecond=0)
    
    # Get or create tracker
    tracker = RateLimitTracker.query.filter_by(api_name=api_name).first()
    
    if not tracker:
        # Create new tracker
        tracker = RateLimitTracker(
            api_name=api_name,
            count=0,
            reset_at=minute_start + timedelta(minutes=1)
        )
        db.session.add(tracker)
        db.session.commit()
    
    # Check if reset time has passed
    if now >= tracker.reset_at:
        tracker.count = 0
        tracker.reset_at = minute_start + timedelta(minutes=1)
        db.session.commit()
        return False
    
    # Check if rate limit exceeded
    return tracker.count >= rate_limit_per_minute

def add_api_call(api_name):
    """
    Increment the API call counter for rate limiting
    
    Args:
        api_name (str): The name of the API ('redmine' or 'openai')
    """
    tracker = RateLimitTracker.query.filter_by(api_name=api_name).first()
    
    if not tracker:
        now = datetime.utcnow()
        minute_start = now.replace(second=0, microsecond=0)
        
        # Create new tracker
        tracker = RateLimitTracker(
            api_name=api_name,
            count=1,
            reset_at=minute_start + timedelta(minutes=1)
        )
        db.session.add(tracker)
    else:
        tracker.count += 1
    
    db.session.commit()
