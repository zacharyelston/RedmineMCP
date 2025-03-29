"""
Routes for the Redmine MCP Extension.
Defines all API endpoints and web UI routes for the application.
Uses file-based configuration instead of database.
"""

import json
import logging
from datetime import datetime
from flask import Blueprint, render_template, request, jsonify, redirect, url_for, flash
from redmine_api import RedmineAPI, create_redmine_client
from llm_factory import create_llm_client
from utils import is_rate_limited, add_api_call, load_credentials, create_credentials_file, update_config_from_credentials
from config import get_config, get_action_logs, log_action, get_prompt_template

logger = logging.getLogger(__name__)

# Create blueprint for main application routes
main = Blueprint('main', __name__)

@main.route('/')
def index():
    """Main page - overview of the integration"""
    config = get_config()
    return render_template('index.html', config=config)

@main.route('/settings', methods=['GET', 'POST'])
def settings():
    """Configuration page for the integration"""
    config = get_config()
    
    if request.method == 'POST':
        # Update configuration from form submission
        redmine_url = request.form.get('redmine_url')
        redmine_api_key = request.form.get('redmine_api_key')
        mcp_url = request.form.get('mcp_url', 'http://localhost:9000')
        rate_limit = int(request.form.get('rate_limit', 60))
        
        # Update credentials.yaml for persistence
        success, message = create_credentials_file(
            redmine_url, 
            redmine_api_key, 
            mcp_url=mcp_url,
            rate_limit_per_minute=rate_limit
        )
        
        if success:
            flash('Configuration saved successfully!', 'success')
            # Force reload configuration
            update_config_from_credentials()
        else:
            flash(f'Error saving configuration: {message}', 'error')
        
        return redirect(url_for('main.settings'))
    
    return render_template('settings.html', config=config)

@main.route('/logs')
def logs():
    """View action logs"""
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    
    # Get logs without pagination
    logs_data = get_action_logs(limit=per_page)
    
    # Simple pagination by slicing the list
    start_idx = (page - 1) * per_page
    end_idx = start_idx + per_page
    logs = logs_data[start_idx:end_idx]
    
    return render_template('logs.html', logs=logs, page=page, has_next=len(logs_data) > end_idx)

@main.route('/prompts', methods=['GET', 'POST'])
def prompts():
    """Manage prompt templates"""
    # In file-based configuration, prompt templates are read-only
    # They are defined in manifest.yaml
    templates = []
    config = get_config()
    if config and 'prompt_templates' in config:
        templates = config['prompt_templates']
    
    return render_template('prompts.html', templates=templates)

@main.route('/api/prompts/<path:template_name>', methods=['GET'])
def get_prompt_template_api(template_name):
    """API endpoint to get a specific prompt template by name"""
    template = get_prompt_template(template_name)
    if not template:
        return jsonify({'error': f'Template {template_name} not found'}), 404
    
    return jsonify(template)

# API ENDPOINTS

@main.route('/api/issues', methods=['GET'])
def get_issues():
    """API endpoint to get Redmine issues"""
    config = get_config()
    if not config:
        return jsonify({'error': 'No configuration found'}), 500
    
    project_id = request.args.get('project_id')
    status_id = request.args.get('status_id')
    limit = request.args.get('limit', 25, type=int)
    
    # Check rate limiting
    if is_rate_limited('redmine', config.get('rate_limit_per_minute', 60)):
        return jsonify({'error': 'Rate limit exceeded'}), 429
    
    try:
        redmine_api = create_redmine_client()
        issues = redmine_api.get_issues(project_id, status_id, limit)
        
        # Record API call for rate limiting
        add_api_call('redmine')
        
        return jsonify({'issues': issues})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@main.route('/api/issues/<int:issue_id>', methods=['GET'])
def get_issue(issue_id):
    """API endpoint to get a specific Redmine issue"""
    config = get_config()
    if not config:
        return jsonify({'error': 'No configuration found'}), 500
    
    # Check rate limiting
    if is_rate_limited('redmine', config.get('rate_limit_per_minute', 60)):
        return jsonify({'error': 'Rate limit exceeded'}), 429
    
    try:
        redmine_api = create_redmine_client()
        issue = redmine_api.get_issue(issue_id)
        
        # Record API call for rate limiting
        add_api_call('redmine')
        
        return jsonify({'issue': issue})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@main.route('/api/llm/create_issue', methods=['POST'])
def llm_create_issue():
    """API endpoint for an LLM to create a Redmine issue"""
    config = get_config()
    if not config:
        return jsonify({'error': 'No configuration found'}), 500
    
    # Get prompt from request
    data = request.get_json()
    prompt = data.get('prompt')
    
    if not prompt:
        return jsonify({'error': 'No prompt provided'}), 400
    
    # Check rate limiting for both APIs
    rate_limit = config.get('rate_limit_per_minute', 60)
    if is_rate_limited('redmine', rate_limit):
        return jsonify({'error': 'Redmine API rate limit exceeded'}), 429
    
    llm_provider = config.get('llm_provider', 'claude-desktop').lower()
    if is_rate_limited(llm_provider, rate_limit):
        return jsonify({'error': f'{llm_provider.capitalize()} API rate limit exceeded'}), 429
    
    try:
        # Generate issue attributes with the configured LLM provider
        llm_api = create_llm_client()
        issue_data = llm_api.generate_issue(prompt)
        
        # Record API call for rate limiting
        add_api_call(llm_provider)
        
        # Create the issue in Redmine
        redmine_api = create_redmine_client()
        
        # Extract required fields from the generated data
        project_id = issue_data.get('project_id', 1)  # Default to project ID 1 if not specified
        subject = issue_data.get('subject')
        description = issue_data.get('description')
        tracker_id = issue_data.get('tracker_id')
        priority_id = issue_data.get('priority_id')
        assigned_to_id = issue_data.get('assigned_to_id')
        
        if not subject or not description:
            return jsonify({'error': 'Generated issue data is missing required fields'}), 500
        
        # Create the issue
        result = redmine_api.create_issue(
            project_id=project_id,
            subject=subject,
            description=description,
            tracker_id=tracker_id,
            priority_id=priority_id,
            assigned_to_id=assigned_to_id
        )
        
        # Record API call for rate limiting
        add_api_call('redmine')
        
        # Log the action
        log_action(
            action_type='create',
            issue_id=result.get('issue', {}).get('id'),
            content=json.dumps(result),
            prompt=prompt,
            response=json.dumps(issue_data)
        )
        
        return jsonify(result)
    
    except Exception as e:
        # Log the error
        log_action(
            action_type='create',
            issue_id=None,
            content='',
            prompt=prompt,
            response='',
            success=False,
            error_message=str(e)
        )
        
        return jsonify({'error': str(e)}), 500

@main.route('/api/llm/update_issue/<int:issue_id>', methods=['POST'])
def llm_update_issue(issue_id):
    """API endpoint for an LLM to update a Redmine issue"""
    config = get_config()
    if not config:
        return jsonify({'error': 'No configuration found'}), 500
    
    # Get prompt from request
    data = request.get_json()
    prompt = data.get('prompt')
    
    if not prompt:
        return jsonify({'error': 'No prompt provided'}), 400
    
    # Check rate limiting for both APIs
    rate_limit = config.get('rate_limit_per_minute', 60)
    if is_rate_limited('redmine', rate_limit):
        return jsonify({'error': 'Redmine API rate limit exceeded'}), 429
    
    llm_provider = config.get('llm_provider', 'claude-desktop').lower()
    if is_rate_limited(llm_provider, rate_limit):
        return jsonify({'error': f'{llm_provider.capitalize()} API rate limit exceeded'}), 429
    
    try:
        # First, get the current issue from Redmine
        redmine_api = create_redmine_client()
        current_issue = redmine_api.get_issue(issue_id)
        
        # Record API call for rate limiting
        add_api_call('redmine')
        
        # Generate update attributes with the configured LLM provider
        llm_api = create_llm_client()
        update_data = llm_api.update_issue(prompt, current_issue)
        
        # Record API call for rate limiting
        add_api_call(llm_provider)
        
        # Extract fields for the update
        subject = update_data.get('subject')
        description = update_data.get('description')
        tracker_id = update_data.get('tracker_id')
        priority_id = update_data.get('priority_id')
        assigned_to_id = update_data.get('assigned_to_id')
        status_id = update_data.get('status_id')
        notes = update_data.get('notes')
        
        # Update the issue
        result = redmine_api.update_issue(
            issue_id=issue_id,
            subject=subject,
            description=description,
            tracker_id=tracker_id,
            priority_id=priority_id,
            assigned_to_id=assigned_to_id,
            status_id=status_id,
            notes=notes
        )
        
        # Record API call for rate limiting
        add_api_call('redmine')
        
        # Log the action
        log_action(
            action_type='update',
            issue_id=issue_id,
            content=json.dumps(result),
            prompt=prompt,
            response=json.dumps(update_data)
        )
        
        return jsonify(result)
    
    except Exception as e:
        # Log the error
        log_action(
            action_type='update',
            issue_id=issue_id,
            content='',
            prompt=prompt,
            response='',
            success=False,
            error_message=str(e)
        )
        
        return jsonify({'error': str(e)}), 500

@main.route('/api/llm/analyze_issue/<int:issue_id>', methods=['POST'])
def llm_analyze_issue(issue_id):
    """API endpoint for an LLM to analyze a Redmine issue"""
    config = get_config()
    if not config:
        return jsonify({'error': 'No configuration found'}), 500
    
    # Check rate limiting for both APIs
    rate_limit = config.get('rate_limit_per_minute', 60)
    if is_rate_limited('redmine', rate_limit):
        return jsonify({'error': 'Redmine API rate limit exceeded'}), 429
    
    llm_provider = config.get('llm_provider', 'claude-desktop').lower()
    if is_rate_limited(llm_provider, rate_limit):
        return jsonify({'error': f'{llm_provider.capitalize()} API rate limit exceeded'}), 429
    
    try:
        # First, get the issue from Redmine
        redmine_api = create_redmine_client()
        issue = redmine_api.get_issue(issue_id)
        
        # Record API call for rate limiting
        add_api_call('redmine')
        
        # Analyze the issue with the configured LLM provider
        llm_api = create_llm_client()
        analysis = llm_api.analyze_issue(issue)
        
        # Record API call for rate limiting
        add_api_call(llm_provider)
        
        # Log the action
        log_action(
            action_type='analyze',
            issue_id=issue_id,
            content=json.dumps(issue),
            prompt='Analysis request',
            response=json.dumps(analysis)
        )
        
        return jsonify(analysis)
    
    except Exception as e:
        # Log the error
        log_action(
            action_type='analyze',
            issue_id=issue_id,
            content='',
            prompt='Analysis request',
            response='',
            success=False,
            error_message=str(e)
        )
        
        return jsonify({'error': str(e)}), 500

# Function to register main routes with Flask app
def register_routes(app):
    """Register routes blueprint with the Flask app"""
    app.register_blueprint(main)
    logger.info("Main routes blueprint registered")