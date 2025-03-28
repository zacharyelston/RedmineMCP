import json
from datetime import datetime, timedelta
from flask import render_template, request, redirect, url_for, flash, jsonify
import logging

from app import app, db
from models import Config, ActionLog, PromptTemplate, RateLimitTracker
from redmine_api import RedmineAPI
from llm_api import LLMAPI
from utils import is_rate_limited, add_api_call

logger = logging.getLogger(__name__)

@app.route('/')
def index():
    """Main page - overview of the integration"""
    config = Config.query.first()
    if not config:
        # If no configuration exists, redirect to settings
        flash('Please configure your Redmine and OpenAI settings first.', 'warning')
        return redirect(url_for('settings'))
    
    # Get some stats for the dashboard
    recent_logs = ActionLog.query.order_by(ActionLog.created_at.desc()).limit(5).all()
    total_actions = ActionLog.query.count()
    success_rate = 0
    if total_actions > 0:
        success_count = ActionLog.query.filter_by(success=True).count()
        success_rate = (success_count / total_actions) * 100
    
    return render_template('index.html', 
                          recent_logs=recent_logs, 
                          total_actions=total_actions, 
                          success_rate=success_rate)

@app.route('/settings', methods=['GET', 'POST'])
def settings():
    """Configuration page for the integration"""
    config = Config.query.first()
    
    if request.method == 'POST':
        if config:
            # Update existing config
            config.redmine_url = request.form['redmine_url']
            config.redmine_api_key = request.form['redmine_api_key']
            config.openai_api_key = request.form['openai_api_key']
            config.rate_limit_per_minute = int(request.form['rate_limit_per_minute'])
        else:
            # Create new config
            config = Config(
                redmine_url=request.form['redmine_url'],
                redmine_api_key=request.form['redmine_api_key'],
                openai_api_key=request.form['openai_api_key'],
                rate_limit_per_minute=int(request.form['rate_limit_per_minute'])
            )
            db.session.add(config)
        
        db.session.commit()
        flash('Configuration saved successfully!', 'success')
        return redirect(url_for('index'))
    
    return render_template('settings.html', config=config)

@app.route('/logs')
def logs():
    """View action logs"""
    page = request.args.get('page', 1, type=int)
    logs = ActionLog.query.order_by(ActionLog.created_at.desc()).paginate(
        page=page, per_page=20, error_out=False)
    return render_template('logs.html', logs=logs)

@app.route('/prompts', methods=['GET', 'POST'])
def prompts():
    """Manage prompt templates"""
    if request.method == 'POST':
        if request.form.get('id'):
            # Update existing template
            template = PromptTemplate.query.get(request.form['id'])
            if template:
                template.name = request.form['name']
                template.description = request.form['description']
                template.template = request.form['template']
                flash('Prompt template updated!', 'success')
        else:
            # Create new template
            template = PromptTemplate(
                name=request.form['name'],
                description=request.form['description'],
                template=request.form['template']
            )
            db.session.add(template)
            flash('Prompt template created!', 'success')
        
        db.session.commit()
        return redirect(url_for('prompts'))
    
    templates = PromptTemplate.query.all()
    return render_template('prompts.html', templates=templates)

@app.route('/api/prompt_template/<int:id>', methods=['GET'])
def get_prompt_template(id):
    """API endpoint to get a specific prompt template"""
    template = PromptTemplate.query.get_or_404(id)
    return jsonify({
        'id': template.id,
        'name': template.name,
        'description': template.description,
        'template': template.template
    })

@app.route('/api/prompt_template/<int:id>', methods=['DELETE'])
def delete_prompt_template(id):
    """API endpoint to delete a prompt template"""
    template = PromptTemplate.query.get_or_404(id)
    db.session.delete(template)
    db.session.commit()
    return jsonify({'success': True})

@app.route('/api/redmine/issues', methods=['GET'])
def get_issues():
    """API endpoint to get Redmine issues"""
    config = Config.query.first()
    if not config:
        return jsonify({'error': 'Configuration not found'}), 400
    
    # Check rate limiting
    if is_rate_limited('redmine', config.rate_limit_per_minute):
        return jsonify({'error': 'Rate limit exceeded'}), 429
    
    try:
        redmine_api = RedmineAPI(config.redmine_url, config.redmine_api_key)
        issues = redmine_api.get_issues(
            project_id=request.args.get('project_id'),
            status_id=request.args.get('status_id'),
            limit=request.args.get('limit', 25, type=int)
        )
        
        # Track API call for rate limiting
        add_api_call('redmine')
        
        return jsonify(issues)
    except Exception as e:
        logger.error(f"Error fetching Redmine issues: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/redmine/issue/<int:issue_id>', methods=['GET'])
def get_issue(issue_id):
    """API endpoint to get a specific Redmine issue"""
    config = Config.query.first()
    if not config:
        return jsonify({'error': 'Configuration not found'}), 400
    
    # Check rate limiting
    if is_rate_limited('redmine', config.rate_limit_per_minute):
        return jsonify({'error': 'Rate limit exceeded'}), 429
    
    try:
        redmine_api = RedmineAPI(config.redmine_url, config.redmine_api_key)
        issue = redmine_api.get_issue(issue_id)
        
        # Track API call for rate limiting
        add_api_call('redmine')
        
        return jsonify(issue)
    except Exception as e:
        logger.error(f"Error fetching Redmine issue {issue_id}: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/llm/create_issue', methods=['POST'])
def llm_create_issue():
    """API endpoint for an LLM to create a Redmine issue"""
    config = Config.query.first()
    if not config:
        return jsonify({'error': 'Configuration not found'}), 400
    
    # Check rate limiting for both APIs
    if is_rate_limited('redmine', config.rate_limit_per_minute) or is_rate_limited('openai', config.rate_limit_per_minute):
        return jsonify({'error': 'Rate limit exceeded'}), 429
    
    try:
        data = request.json
        prompt = data.get('prompt')
        if not prompt:
            return jsonify({'error': 'Prompt is required'}), 400
        
        # Initialize APIs
        llm_api = LLMAPI(config.openai_api_key)
        redmine_api = RedmineAPI(config.redmine_url, config.redmine_api_key)
        
        # Use LLM to generate issue attributes
        issue_data = llm_api.generate_issue(prompt)
        add_api_call('openai')
        
        # Create the issue in Redmine
        issue = redmine_api.create_issue(
            project_id=issue_data.get('project_id'),
            subject=issue_data.get('subject'),
            description=issue_data.get('description'),
            tracker_id=issue_data.get('tracker_id'),
            priority_id=issue_data.get('priority_id'),
            assigned_to_id=issue_data.get('assigned_to_id')
        )
        add_api_call('redmine')
        
        # Log the action
        log = ActionLog(
            action_type='create',
            issue_id=issue.get('id'),
            content=json.dumps(issue),
            prompt=prompt,
            response=json.dumps(issue_data),
            success=True
        )
        db.session.add(log)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'issue': issue
        })
    except Exception as e:
        # Log the error
        log = ActionLog(
            action_type='create',
            content='Failed to create issue',
            prompt=request.json.get('prompt', ''),
            response='',
            success=False,
            error_message=str(e)
        )
        db.session.add(log)
        db.session.commit()
        
        logger.error(f"Error creating issue through LLM: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/llm/update_issue/<int:issue_id>', methods=['POST'])
def llm_update_issue(issue_id):
    """API endpoint for an LLM to update a Redmine issue"""
    config = Config.query.first()
    if not config:
        return jsonify({'error': 'Configuration not found'}), 400
    
    # Check rate limiting for both APIs
    if is_rate_limited('redmine', config.rate_limit_per_minute) or is_rate_limited('openai', config.rate_limit_per_minute):
        return jsonify({'error': 'Rate limit exceeded'}), 429
    
    try:
        data = request.json
        prompt = data.get('prompt')
        if not prompt:
            return jsonify({'error': 'Prompt is required'}), 400
        
        # Initialize APIs
        llm_api = LLMAPI(config.openai_api_key)
        redmine_api = RedmineAPI(config.redmine_url, config.redmine_api_key)
        
        # Get the current issue to provide context to the LLM
        current_issue = redmine_api.get_issue(issue_id)
        add_api_call('redmine')
        
        # Use LLM to generate updated issue attributes
        update_data = llm_api.update_issue(prompt, current_issue)
        add_api_call('openai')
        
        # Update the issue in Redmine
        updated_issue = redmine_api.update_issue(
            issue_id=issue_id,
            subject=update_data.get('subject'),
            description=update_data.get('description'),
            tracker_id=update_data.get('tracker_id'),
            priority_id=update_data.get('priority_id'),
            assigned_to_id=update_data.get('assigned_to_id'),
            status_id=update_data.get('status_id'),
            notes=update_data.get('notes')
        )
        add_api_call('redmine')
        
        # Log the action
        log = ActionLog(
            action_type='update',
            issue_id=issue_id,
            content=json.dumps(updated_issue),
            prompt=prompt,
            response=json.dumps(update_data),
            success=True
        )
        db.session.add(log)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'issue': updated_issue
        })
    except Exception as e:
        # Log the error
        log = ActionLog(
            action_type='update',
            issue_id=issue_id,
            content=f'Failed to update issue {issue_id}',
            prompt=request.json.get('prompt', ''),
            response='',
            success=False,
            error_message=str(e)
        )
        db.session.add(log)
        db.session.commit()
        
        logger.error(f"Error updating issue {issue_id} through LLM: {str(e)}")
        return jsonify({'error': str(e)}), 500

@app.route('/api/llm/analyze_issue/<int:issue_id>', methods=['POST'])
def llm_analyze_issue(issue_id):
    """API endpoint for an LLM to analyze a Redmine issue"""
    config = Config.query.first()
    if not config:
        return jsonify({'error': 'Configuration not found'}), 400
    
    # Check rate limiting for both APIs
    if is_rate_limited('redmine', config.rate_limit_per_minute) or is_rate_limited('openai', config.rate_limit_per_minute):
        return jsonify({'error': 'Rate limit exceeded'}), 429
    
    try:
        # Initialize APIs
        llm_api = LLMAPI(config.openai_api_key)
        redmine_api = RedmineAPI(config.redmine_url, config.redmine_api_key)
        
        # Get the issue to analyze
        issue = redmine_api.get_issue(issue_id)
        add_api_call('redmine')
        
        # Use LLM to analyze the issue
        analysis = llm_api.analyze_issue(issue)
        add_api_call('openai')
        
        # Log the action
        log = ActionLog(
            action_type='analyze',
            issue_id=issue_id,
            content=json.dumps(issue),
            prompt=f"Analyze issue {issue_id}",
            response=json.dumps(analysis),
            success=True
        )
        db.session.add(log)
        db.session.commit()
        
        return jsonify({
            'success': True,
            'analysis': analysis
        })
    except Exception as e:
        # Log the error
        log = ActionLog(
            action_type='analyze',
            issue_id=issue_id,
            content=f'Failed to analyze issue {issue_id}',
            prompt=f"Analyze issue {issue_id}",
            response='',
            success=False,
            error_message=str(e)
        )
        db.session.add(log)
        db.session.commit()
        
        logger.error(f"Error analyzing issue {issue_id} through LLM: {str(e)}")
        return jsonify({'error': str(e)}), 500
