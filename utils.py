import os
import yaml
from datetime import datetime, timedelta
from app import db
from models import RateLimitTracker, Config

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

def load_credentials():
    """
    Load credentials from credentials.yaml file
    
    Returns:
        dict: The loaded credentials or None if file not found
    """
    credentials_path = os.path.join(os.getcwd(), 'credentials.yaml')
    
    # Check if credentials file exists
    if not os.path.exists(credentials_path):
        return None
    
    # Load credentials from file
    try:
        with open(credentials_path, 'r') as file:
            credentials = yaml.safe_load(file)
        return credentials
    except Exception as e:
        print(f"Error loading credentials: {e}")
        return None


def update_config_from_credentials():
    """
    Updates the application configuration from credentials.yaml file
    
    Returns:
        tuple: (bool, str) - Success status and message
    """
    credentials = load_credentials()
    
    if not credentials:
        return False, "Credentials file not found or invalid."
    
    try:
        # Get or create config
        config = Config.query.first()
        if not config:
            config = Config(
                redmine_url="",
                redmine_api_key="",
                openai_api_key="",
                rate_limit_per_minute=60
            )
            db.session.add(config)
        
        # Update config from credentials
        # First, check for the new flat format (used in setup scripts)
        if 'redmine_url' in credentials:
            config.redmine_url = credentials['redmine_url']
        
        if 'redmine_api_key' in credentials:
            config.redmine_api_key = credentials['redmine_api_key']
        
        if 'openai_api_key' in credentials:
            config.openai_api_key = credentials['openai_api_key']
        
        if 'rate_limit_per_minute' in credentials:
            config.rate_limit_per_minute = credentials['rate_limit_per_minute']
        
        # Also check for the nested format (for backward compatibility)
        if 'redmine' in credentials:
            if 'url' in credentials['redmine']:
                config.redmine_url = credentials['redmine']['url']
            if 'api_key' in credentials['redmine']:
                config.redmine_api_key = credentials['redmine']['api_key']
        
        if 'openai' in credentials and 'api_key' in credentials['openai']:
            config.openai_api_key = credentials['openai']['api_key']
        
        if 'rate_limits' in credentials and 'redmine_per_minute' in credentials['rate_limits']:
            config.rate_limit_per_minute = credentials['rate_limits']['redmine_per_minute']
        
        db.session.commit()
        return True, "Configuration updated successfully from credentials.yaml."
    except Exception as e:
        db.session.rollback()
        return False, f"Error updating configuration: {e}"


def create_credentials_file(redmine_url, redmine_api_key, openai_api_key, rate_limit_per_minute=60):
    """
    Creates a credentials.yaml file with the provided settings
    
    Args:
        redmine_url (str): The Redmine instance URL
        redmine_api_key (str): The Redmine API key
        openai_api_key (str): The OpenAI API key
        rate_limit_per_minute (int, optional): Rate limit for API calls
        
    Returns:
        tuple: (bool, str) - Success status and message
    """
    # Using the flat format consistent with the setup scripts
    credentials = {
        'redmine_url': redmine_url,
        'redmine_api_key': redmine_api_key,
        'openai_api_key': openai_api_key,
        'rate_limit_per_minute': rate_limit_per_minute
    }
    
    try:
        credentials_path = os.path.join(os.getcwd(), 'credentials.yaml')
        with open(credentials_path, 'w') as file:
            yaml.dump(credentials, file, default_flow_style=False)
        return True, "Credentials file created successfully."
    except Exception as e:
        return False, f"Error creating credentials file: {e}"