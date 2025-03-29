"""
Routes for the Redmine MCP Extension.
Defines all API endpoints and web UI routes for the application.
"""

import json
import logging
from datetime import datetime
from flask import Blueprint, render_template, request, jsonify, redirect, url_for, flash
from models import db, Config, ActionLog, PromptTemplate, RateLimitTracker
from redmine_api import RedmineAPI
from llm_factory import create_llm_client
from utils import is_rate_limited, add_api_call, load_credentials, create_credentials_file, update_config_from_credentials

logger = logging.getLogger(__name__)

# Create blueprint for main application routes
main = Blueprint('main', __name__)

@main.route('/')
def index():
    """Main page - overview of the integration"""
    config = Config.query.first()
    return render_template('index.html', config=config)

@main.route('/settings', methods=['GET', 'POST'])
def settings():
    """Configuration page for the integration"""
    config = Config.query.first()
    
    if request.method == 'POST':
        # Update configuration from form submission
        redmine_url = request.form.get('redmine_url')
        redmine_api_key = request.form.get('redmine_api_key')
        claude_api_key = request.form.get('claude_api_key')
        llm_provider = 'claude'  # Only Claude is supported
        rate_limit = int(request.form.get('rate_limit', 60))
        
        # Create or update config
        if config:
            config.redmine_url = redmine_url
            config.redmine_api_key = redmine_api_key
            config.claude_api_key = claude_api_key
            config.llm_provider = llm_provider
            config.rate_limit_per_minute = rate_limit
            config.updated_at = datetime.utcnow()
        else:
            config = Config(
                redmine_url=redmine_url,
                redmine_api_key=redmine_api_key,
                claude_api_key=claude_api_key,
                llm_provider=llm_provider,
                rate_limit_per_minute=rate_limit
            )
            db.session.add(config)
        
        # Also update credentials.yaml for persistence
        success, message = create_credentials_file(
            redmine_url, 
            redmine_api_key, 
            claude_api_key=claude_api_key,
            rate_limit_per_minute=rate_limit
        )
        
        db.session.commit()
        
        if success:
            flash('Configuration saved successfully!', 'success')
        else:
            flash(f'Configuration saved to database but not to credentials file: {message}', 'warning')
        
        return redirect(url_for('main.settings'))
    
    return render_template('settings.html', config=config)

@main.route('/logs')
def logs():
    """View action logs"""
    page = request.args.get('page', 1, type=int)
    per_page = request.args.get('per_page', 20, type=int)
    
    # Get logs with pagination
    logs = ActionLog.query.order_by(ActionLog.created_at.desc()).paginate(
        page=page, per_page=per_page, error_out=False
    )
    
    return render_template('logs.html', logs=logs)

@main.route('/prompts', methods=['GET', 'POST'])
def prompts():
    """Manage prompt templates"""
    if request.method == 'POST':
        # Create or update a prompt template
        template_id = request.form.get('id')
        name = request.form.get('name')
        description = request.form.get('description')
        template = request.form.get('template')
        
        if template_id:
            # Update existing template
            prompt_template = PromptTemplate.query.get(template_id)
            if prompt_template:
                prompt_template.name = name
                prompt_template.description = description
                prompt_template.template = template
                prompt_template.updated_at = datetime.utcnow()
                flash('Prompt template updated successfully!', 'success')
            else:
                flash('Prompt template not found!', 'error')
        else:
            # Create new template
            prompt_template = PromptTemplate(
                name=name,
                description=description,
                template=template
            )
            db.session.add(prompt_template)
            flash('Prompt template created successfully!', 'success')
        
        db.session.commit()
        return redirect(url_for('main.prompts'))
    
    templates = PromptTemplate.query.all()
    return render_template('prompts.html', templates=templates)

@main.route('/api/prompts/<int:id>', methods=['GET'])
def get_prompt_template(id):
    """API endpoint to get a specific prompt template"""
    template = PromptTemplate.query.get_or_404(id)
    return jsonify({
        'id': template.id,
        'name': template.name,
        'description': template.description,
        'template': template.template
    })

@main.route('/api/prompts/<int:id>', methods=['DELETE'])
def delete_prompt_template(id):
    """API endpoint to delete a prompt template"""
    template = PromptTemplate.query.get_or_404(id)
    db.session.delete(template)
    db.session.commit()
    return jsonify({'success': True, 'message': 'Template deleted successfully'})

# API ENDPOINTS

@main.route('/api/issues', methods=['GET'])
def get_issues():
    """API endpoint to get Redmine issues"""
    config = Config.query.first()
    if not config:
        return jsonify({'error': 'No configuration found'}), 500
    
    project_id = request.args.get('project_id')
    status_id = request.args.get('status_id')
    limit = request.args.get('limit', 25, type=int)
    
    # Check rate limiting
    if is_rate_limited('redmine', config.rate_limit_per_minute):
        return jsonify({'error': 'Rate limit exceeded'}), 429
    
    try:
        redmine_api = RedmineAPI(config.redmine_url, config.redmine_api_key)
        issues = redmine_api.get_issues(project_id, status_id, limit)
        
        # Record API call for rate limiting
        add_api_call('redmine')
        
        return jsonify({'issues': issues})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@main.route('/api/issues/<int:issue_id>', methods=['GET'])
def get_issue(issue_id):
    """API endpoint to get a specific Redmine issue"""
    config = Config.query.first()
    if not config:
        return jsonify({'error': 'No configuration found'}), 500
    
    # Check rate limiting
    if is_rate_limited('redmine', config.rate_limit_per_minute):
        return jsonify({'error': 'Rate limit exceeded'}), 429
    
    try:
        redmine_api = RedmineAPI(config.redmine_url, config.redmine_api_key)
        issue = redmine_api.get_issue(issue_id)
        
        # Record API call for rate limiting
        add_api_call('redmine')
        
        return jsonify({'issue': issue})
    
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@main.route('/api/llm/create_issue', methods=['POST'])
def llm_create_issue():
    """API endpoint for an LLM to create a Redmine issue"""
    config = Config.query.first()
    if not config:
        return jsonify({'error': 'No configuration found'}), 500
    
    # Get prompt from request
    data = request.get_json()
    prompt = data.get('prompt')
    
    if not prompt:
        return jsonify({'error': 'No prompt provided'}), 400
    
    # Check rate limiting for both APIs
    if is_rate_limited('redmine', config.rate_limit_per_minute):
        return jsonify({'error': 'Redmine API rate limit exceeded'}), 429
    
    llm_provider = config.llm_provider.lower()
    if is_rate_limited(llm_provider, config.rate_limit_per_minute):
        return jsonify({'error': f'{llm_provider.capitalize()} API rate limit exceeded'}), 429
    
    try:
        # Generate issue attributes with the configured LLM provider
        llm_api = create_llm_client(config)
        issue_data = llm_api.generate_issue(prompt)
        
        # Record API call for rate limiting
        add_api_call(llm_provider)
        
        # Create the issue in Redmine
        redmine_api = RedmineAPI(config.redmine_url, config.redmine_api_key)
        
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
        log_entry = ActionLog(
            action_type='create',
            issue_id=result.get('issue', {}).get('id'),
            content=json.dumps(result),
            prompt=prompt,
            response=json.dumps(issue_data),
            success=True
        )
        db.session.add(log_entry)
        db.session.commit()
        
        return jsonify(result)
    
    except Exception as e:
        # Log the error
        log_entry = ActionLog(
            action_type='create',
            issue_id=None,
            content='',
            prompt=prompt,
            response='',
            success=False,
            error_message=str(e)
        )
        db.session.add(log_entry)
        db.session.commit()
        
        return jsonify({'error': str(e)}), 500

@main.route('/api/llm/update_issue/<int:issue_id>', methods=['POST'])
def llm_update_issue(issue_id):
    """API endpoint for an LLM to update a Redmine issue"""
    config = Config.query.first()
    if not config:
        return jsonify({'error': 'No configuration found'}), 500
    
    # Get prompt from request
    data = request.get_json()
    prompt = data.get('prompt')
    
    if not prompt:
        return jsonify({'error': 'No prompt provided'}), 400
    
    # Check rate limiting for both APIs
    if is_rate_limited('redmine', config.rate_limit_per_minute):
        return jsonify({'error': 'Redmine API rate limit exceeded'}), 429
    
    llm_provider = config.llm_provider.lower()
    if is_rate_limited(llm_provider, config.rate_limit_per_minute):
        return jsonify({'error': f'{llm_provider.capitalize()} API rate limit exceeded'}), 429
    
    try:
        # First, get the current issue from Redmine
        redmine_api = RedmineAPI(config.redmine_url, config.redmine_api_key)
        current_issue = redmine_api.get_issue(issue_id)
        
        # Record API call for rate limiting
        add_api_call('redmine')
        
        # Generate update attributes with the configured LLM provider
        llm_api = create_llm_client(config)
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
        log_entry = ActionLog(
            action_type='update',
            issue_id=issue_id,
            content=json.dumps(result),
            prompt=prompt,
            response=json.dumps(update_data),
            success=True
        )
        db.session.add(log_entry)
        db.session.commit()
        
        return jsonify(result)
    
    except Exception as e:
        # Log the error
        log_entry = ActionLog(
            action_type='update',
            issue_id=issue_id,
            content='',
            prompt=prompt,
            response='',
            success=False,
            error_message=str(e)
        )
        db.session.add(log_entry)
        db.session.commit()
        
        return jsonify({'error': str(e)}), 500

@main.route('/api/llm/analyze_issue/<int:issue_id>', methods=['POST'])
def llm_analyze_issue(issue_id):
    """API endpoint for an LLM to analyze a Redmine issue"""
    config = Config.query.first()
    if not config:
        return jsonify({'error': 'No configuration found'}), 500
    
    # Check rate limiting for both APIs
    if is_rate_limited('redmine', config.rate_limit_per_minute):
        return jsonify({'error': 'Redmine API rate limit exceeded'}), 429
    
    llm_provider = config.llm_provider.lower()
    if is_rate_limited(llm_provider, config.rate_limit_per_minute):
        return jsonify({'error': f'{llm_provider.capitalize()} API rate limit exceeded'}), 429
    
    try:
        # First, get the issue from Redmine
        redmine_api = RedmineAPI(config.redmine_url, config.redmine_api_key)
        issue = redmine_api.get_issue(issue_id)
        
        # Record API call for rate limiting
        add_api_call('redmine')
        
        # Analyze the issue with the configured LLM provider
        llm_api = create_llm_client(config)
        analysis = llm_api.analyze_issue(issue)
        
        # Record API call for rate limiting
        add_api_call(llm_provider)
        
        # Log the action
        log_entry = ActionLog(
            action_type='analyze',
            issue_id=issue_id,
            content=json.dumps(issue),
            prompt='Analysis request',
            response=json.dumps(analysis),
            success=True
        )
        db.session.add(log_entry)
        db.session.commit()
        
        return jsonify(analysis)
    
    except Exception as e:
        # Log the error
        log_entry = ActionLog(
            action_type='analyze',
            issue_id=issue_id,
            content='',
            prompt='Analysis request',
            response='',
            success=False,
            error_message=str(e)
        )
        db.session.add(log_entry)
        db.session.commit()
        
        return jsonify({'error': str(e)}), 500

# Function to register main routes with Flask app
def register_routes(app):
    """Register routes blueprint with the Flask app"""
    app.register_blueprint(main)
    logger.info("Main routes blueprint registered")