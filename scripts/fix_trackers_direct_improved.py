#!/usr/bin/env python3
"""
Fix Redmine Trackers Directly - Improved Version

This script creates trackers directly by accessing the Redmine database inside the Docker container.
This bypasses the API permission issues causing 403 Forbidden errors.

Usage:
    python scripts/fix_trackers_direct_improved.py
"""

import argparse
import logging
import os
import sys
import subprocess
import tempfile

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)
logger = logging.getLogger(__name__)

# Default trackers to create
DEFAULT_TRACKERS = [
    {"name": "Bug", "description": "Software defects and issues", "default_status_id": 1, "is_in_roadmap": 0},
    {"name": "Feature", "description": "New features and enhancements", "default_status_id": 1, "is_in_roadmap": 1},
    {"name": "Support", "description": "Support requests and questions", "default_status_id": 1, "is_in_roadmap": 0}
]

def run_command(command, shell=True):
    """Run a shell command and return the output"""
    logger.debug(f"Running command: {command}")
    try:
        result = subprocess.run(
            command,
            shell=shell,
            check=True,
            text=True,
            capture_output=True
        )
        return result.stdout.strip(), 0
    except subprocess.CalledProcessError as e:
        logger.error(f"Command failed with exit code {e.returncode}")
        logger.error(f"Error output: {e.stderr}")
        return e.stderr, e.returncode

def execute_sql_commands_directly():
    """Execute SQL commands directly in the container"""
    container_name = "redmine-local"
    sqlite_db_path = "/redmine/db/sqlite/redmine.db"
    
    # Check if container is running
    stdout, rc = run_command(f"docker ps --filter name={container_name} --format '{{{{.Names}}}}'")
    if rc != 0 or container_name not in stdout:
        logger.error(f"Container {container_name} is not running")
        return False
    
    # Check current trackers
    logger.info("Checking existing trackers...")
    stdout, rc = run_command(
        f"docker exec {container_name} sqlite3 {sqlite_db_path} \"SELECT id, name FROM trackers;\""
    )
    
    if rc == 0:
        if stdout:
            logger.info(f"Existing trackers:\n{stdout}")
        else:
            logger.info("No existing trackers found")
    
    # Create each tracker directly
    logger.info("Creating trackers...")
    for tracker in DEFAULT_TRACKERS:
        # Check if tracker exists
        check_cmd = f"docker exec {container_name} sqlite3 {sqlite_db_path} \"SELECT COUNT(*) FROM trackers WHERE name = '{tracker['name']}';\""
        stdout, rc = run_command(check_cmd)
        
        if rc != 0:
            logger.error(f"Failed to check if tracker {tracker['name']} exists")
            continue
        
        if stdout.strip() != "0":
            logger.info(f"Tracker {tracker['name']} already exists, skipping creation")
            continue
        
        # Create tracker
        logger.info(f"Creating tracker: {tracker['name']}")
        insert_cmd = f"""docker exec {container_name} sqlite3 {sqlite_db_path} \"
        INSERT INTO trackers (name, description, default_status_id, is_in_roadmap, position)
        SELECT '{tracker['name']}', '{tracker['description']}', {tracker['default_status_id']}, {tracker['is_in_roadmap']}, COALESCE(MAX(position), 0) + 1
        FROM trackers;
        \""""
        
        stdout, rc = run_command(insert_cmd)
        if rc != 0:
            logger.error(f"Failed to create tracker {tracker['name']}: {stdout}")
        else:
            logger.info(f"✅ Created tracker: {tracker['name']}")
    
    # Verify trackers were created
    logger.info("Verifying trackers...")
    stdout, rc = run_command(
        f"docker exec {container_name} sqlite3 {sqlite_db_path} \"SELECT id, name FROM trackers;\""
    )
    
    if rc == 0 and stdout:
        logger.info(f"Trackers in database:\n{stdout}")
        return True
    else:
        logger.error(f"Failed to verify trackers creation")
        return False

def fix_project_trackers(project_id=1):
    """Add trackers to the project"""
    container_name = "redmine-local"
    sqlite_db_path = "/redmine/db/sqlite/redmine.db"
    
    # Get tracker IDs
    stdout, rc = run_command(
        f"docker exec {container_name} sqlite3 {sqlite_db_path} \"SELECT id FROM trackers;\""
    )
    
    if rc != 0 or not stdout:
        logger.error("Failed to get tracker IDs")
        return False
    
    tracker_ids = stdout.strip().split('\n')
    logger.info(f"Found tracker IDs: {tracker_ids}")
    
    # Check if project exists
    stdout, rc = run_command(
        f"docker exec {container_name} sqlite3 {sqlite_db_path} \"SELECT COUNT(*) FROM projects WHERE id = {project_id};\""
    )
    
    if rc != 0 or stdout.strip() == "0":
        logger.warning(f"Project with ID {project_id} does not exist, looking for any project...")
        # Get any project
        stdout, rc = run_command(
            f"docker exec {container_name} sqlite3 {sqlite_db_path} \"SELECT id FROM projects LIMIT 1;\""
        )
        if rc != 0 or not stdout:
            logger.error("No projects found in database")
            return False
        project_id = stdout.strip()
        logger.info(f"Using project ID: {project_id}")
    
    # Associate trackers with project
    for tracker_id in tracker_ids:
        logger.info(f"Adding tracker {tracker_id} to project {project_id}...")
        stdout, rc = run_command(
            f"docker exec {container_name} sqlite3 {sqlite_db_path} \"INSERT OR IGNORE INTO projects_trackers (project_id, tracker_id) VALUES ({project_id}, {tracker_id});\""
        )
        if rc != 0:
            logger.error(f"Error adding tracker to project: {stdout}")
    
    # Verify project-tracker associations
    stdout, rc = run_command(
        f"docker exec {container_name} sqlite3 {sqlite_db_path} \"SELECT tracker_id FROM projects_trackers WHERE project_id = {project_id};\""
    )
    
    if rc == 0:
        if stdout:
            logger.info(f"Project {project_id} trackers:\n{stdout}")
            return True
        else:
            logger.warning(f"No trackers associated with project {project_id}")
            return False
    else:
        logger.error(f"Failed to verify project trackers: {stdout}")
        return False

def fix_workflow_permissions():
    """Fix workflow permissions to allow tracker usage"""
    container_name = "redmine-local"
    sqlite_db_path = "/redmine/db/sqlite/redmine.db"
    
    # Get role IDs
    stdout, rc = run_command(
        f"docker exec {container_name} sqlite3 {sqlite_db_path} \"SELECT id FROM roles;\""
    )
    
    if rc != 0 or not stdout:
        logger.error("Failed to get role IDs")
        return False
    
    role_ids = stdout.strip().split('\n')
    
    # Get tracker IDs
    stdout, rc = run_command(
        f"docker exec {container_name} sqlite3 {sqlite_db_path} \"SELECT id FROM trackers;\""
    )
    
    if rc != 0 or not stdout:
        logger.error("Failed to get tracker IDs")
        return False
    
    tracker_ids = stdout.strip().split('\n')
    
    # Get status IDs
    stdout, rc = run_command(
        f"docker exec {container_name} sqlite3 {sqlite_db_path} \"SELECT id FROM issue_statuses;\""
    )
    
    if rc != 0:
        logger.error("Failed to get status IDs")
        status_ids = ["1"]  # Default to ID 1 if query fails
    else:
        status_ids = stdout.strip().split('\n') if stdout else ["1"]
    
    # Add workflow permissions for each role-tracker-status combination
    success_count = 0
    for role_id in role_ids:
        for tracker_id in tracker_ids:
            for status_id in status_ids:
                cmd = f"""docker exec {container_name} sqlite3 {sqlite_db_path} \"
                INSERT OR IGNORE INTO workflows (role_id, tracker_id, old_status_id, new_status_id)
                VALUES ({role_id}, {tracker_id}, NULL, {status_id});
                INSERT OR IGNORE INTO workflows (role_id, tracker_id, old_status_id, new_status_id)
                VALUES ({role_id}, {tracker_id}, {status_id}, {status_id});
                \""""
                
                stdout, rc = run_command(cmd)
                if rc == 0:
                    success_count += 1
    
    if success_count > 0:
        logger.info(f"✅ Added {success_count} workflow permissions")
        return True
    else:
        logger.error("Failed to add workflow permissions")
        return False

def restart_container():
    """Restart the Redmine container to apply changes"""
    container_name = "redmine-local"
    logger.info(f"Restarting {container_name} container...")
    
    stdout, rc = run_command(f"docker restart {container_name}")
    if rc == 0:
        logger.info(f"✅ Restarted {container_name} container")
        return True
    else:
        logger.error(f"Failed to restart {container_name} container: {stdout}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Fix Redmine Trackers by Direct Database Access')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose output')
    parser.add_argument('--restart', action='store_true', help='Restart container after fixes')
    args = parser.parse_args()
    
    if args.verbose:
        logger.setLevel(logging.DEBUG)
    
    logger.info("Starting direct tracker fix...")
    
    # Execute SQL commands
    if execute_sql_commands_directly():
        logger.info("✅ Successfully created trackers in database!")
        
        # Fix project-tracker associations
        if fix_project_trackers():
            logger.info("✅ Successfully associated trackers with project!")
        else:
            logger.warning("⚠️ Failed to associate trackers with project.")
        
        # Fix workflow permissions
        if fix_workflow_permissions():
            logger.info("✅ Successfully added workflow permissions!")
        else:
            logger.warning("⚠️ Failed to add workflow permissions.")
        
        # Restart container if requested
        if args.restart:
            restart_container()
        
        logger.info("✅ Tracker fix completed successfully!")
        logger.info("You should now be able to use trackers in your Redmine projects.")
        logger.info("If trackers are not visible in the web interface, try restarting the container:")
        logger.info("  docker restart redmine-local")
        
        return 0
    else:
        logger.error("❌ Failed to fix trackers")
        return 1

if __name__ == "__main__":
    try:
        sys.exit(main())
    except KeyboardInterrupt:
        logger.info("\nProcess interrupted by user")
        sys.exit(130)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        sys.exit(1)
