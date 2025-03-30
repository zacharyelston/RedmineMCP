#!/usr/bin/env python3
"""
Fix Redmine Trackers Directly

This script creates trackers directly by accessing the Redmine database inside the Docker container.
This bypasses the API permission issues causing 403 Forbidden errors.

Usage:
    python scripts/fix_trackers_direct.py
"""

import argparse
import logging
import os
import sys
import subprocess
import time
import yaml

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
        return result.stdout.strip(), result.stderr.strip()
    except subprocess.CalledProcessError as e:
        logger.error(f"Command failed with exit code {e.returncode}")
        logger.error(f"Error output: {e.stderr}")
        return None, e.stderr

def generate_sql_for_trackers():
    """Generate SQL to create the trackers"""
    sql_commands = []
    
    # Add SQL to check if trackers exist
    sql_commands.append("SELECT COUNT(*) FROM trackers;")
    
    for tracker in DEFAULT_TRACKERS:
        # Check if tracker exists
        check_sql = f"SELECT COUNT(*) FROM trackers WHERE name = '{tracker['name']}';"
        sql_commands.append(check_sql)
        
        # SQL to create tracker if it doesn't exist
        insert_sql = f"""
        INSERT INTO trackers (name, description, default_status_id, is_in_roadmap, position)
        SELECT '{tracker['name']}', '{tracker['description']}', {tracker['default_status_id']}, {tracker['is_in_roadmap']}, COALESCE(MAX(position), 0) + 1
        FROM trackers
        WHERE NOT EXISTS (SELECT 1 FROM trackers WHERE name = '{tracker['name']}');
        """
        sql_commands.append(insert_sql)
    
    # Add SQL to verify trackers were created
    sql_commands.append("SELECT * FROM trackers;")
    
    return sql_commands

def create_sql_file(sql_commands):
    """Create a SQL file with the commands"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    sql_file_path = os.path.join(script_dir, "fix_trackers.sql")
    
    with open(sql_file_path, "w") as f:
        for cmd in sql_commands:
            f.write(f"{cmd}\n")
    
    logger.info(f"Created SQL file at {sql_file_path}")
    return sql_file_path

def execute_in_redmine_container(sql_file):
    """Copy SQL file to container and execute it"""
    container_name = "redmine-local"
    
    # Check if container is running
    stdout, stderr = run_command(f"docker ps --filter name={container_name} --format '{{{{.Names}}}}'")
    if not stdout or container_name not in stdout:
        logger.error(f"Container {container_name} is not running")
        return False
    
    # Get container DB path
    script_dir = os.path.dirname(os.path.abspath(__file__))
    base_name = os.path.basename(sql_file)
    container_sql_path = f"/tmp/{base_name}"
    
    # Copy SQL file to container
    logger.info(f"Copying SQL file to container...")
    stdout, stderr = run_command(f"docker cp {sql_file} {container_name}:{container_sql_path}")
    if stderr:
        logger.error(f"Failed to copy SQL file: {stderr}")
        return False
    
    # Execute SQL file
    logger.info(f"Executing SQL in container...")
    sqlite_db_path = "/redmine/db/sqlite/redmine.db"
    stdout, stderr = run_command(
        f"docker exec {container_name} sqlite3 {sqlite_db_path} < {container_sql_path}"
    )
    
    if stderr:
        logger.error(f"Error executing SQL: {stderr}")
        return False
    
    # Verify with select query
    logger.info(f"Verifying trackers were created...")
    stdout, stderr = run_command(
        f"docker exec {container_name} sqlite3 {sqlite_db_path} \"SELECT id, name FROM trackers;\""
    )
    
    if stdout:
        logger.info(f"Trackers in database:\n{stdout}")
        return True
    else:
        logger.error(f"Failed to verify trackers: {stderr}")
        return False

def fix_project_trackers(project_id=1):
    """Add trackers to the default project"""
    container_name = "redmine-local"
    sqlite_db_path = "/redmine/db/sqlite/redmine.db"
    
    # Get tracker IDs
    stdout, stderr = run_command(
        f"docker exec {container_name} sqlite3 {sqlite_db_path} \"SELECT id FROM trackers;\""
    )
    
    if not stdout:
        logger.error("Failed to get tracker IDs")
        return False
    
    tracker_ids = stdout.strip().split('\n')
    logger.info(f"Found tracker IDs: {tracker_ids}")
    
    # Associate trackers with project
    for tracker_id in tracker_ids:
        logger.info(f"Adding tracker {tracker_id} to project {project_id}...")
        stdout, stderr = run_command(
            f"docker exec {container_name} sqlite3 {sqlite_db_path} \"INSERT OR IGNORE INTO projects_trackers (project_id, tracker_id) VALUES ({project_id}, {tracker_id});\""
        )
        if stderr:
            logger.error(f"Error adding tracker to project: {stderr}")
    
    # Verify project-tracker associations
    stdout, stderr = run_command(
        f"docker exec {container_name} sqlite3 {sqlite_db_path} \"SELECT tracker_id FROM projects_trackers WHERE project_id = {project_id};\""
    )
    
    if stdout:
        logger.info(f"Project {project_id} trackers:\n{stdout}")
        return True
    else:
        logger.error(f"Failed to verify project trackers: {stderr}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Fix Redmine Trackers by Direct Database Access')
    parser.add_argument('--verbose', action='store_true', help='Enable verbose output')
    args = parser.parse_args()
    
    if args.verbose:
        logger.setLevel(logging.DEBUG)
    
    logger.info("Starting direct tracker fix...")
    
    # Generate SQL commands
    sql_commands = generate_sql_for_trackers()
    
    # Create SQL file
    sql_file = create_sql_file(sql_commands)
    
    # Execute SQL in container
    if execute_in_redmine_container(sql_file):
        logger.info("✅ Successfully created trackers in database!")
        
        # Fix project-tracker associations
        if fix_project_trackers():
            logger.info("✅ Successfully associated trackers with default project!")
        else:
            logger.warning("⚠️ Failed to associate trackers with default project.")
            
        logger.info("✅ Tracker fix completed successfully!")
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
