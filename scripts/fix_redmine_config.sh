#!/bin/bash
# Script to fix Redmine configuration issues

set -e

echo "Running fix_redmine_config.sh..."

# Ensure we're in the Redmine directory
cd /usr/src/redmine

# Create a config/secrets.yml file with the secret key base
mkdir -p config
cat > config/secrets.yml <<EOF
production:
  secret_key_base: "${REDMINE_SECRET_KEY_BASE}"
EOF

# Enable the REST API if needed
if [ ! -f config/configuration.yml ]; then
  mkdir -p config
  cat > config/configuration.yml <<EOF
production:
  rest_api_enabled: true
  jsonp_enabled: true
EOF
else
  # Check if REST API is already enabled
  if ! grep -q "rest_api_enabled" config/configuration.yml; then
    # Add REST API configuration
    cat >> config/configuration.yml <<EOF
production:
  rest_api_enabled: true
  jsonp_enabled: true
EOF
  fi
fi

# Create default trackers directly in the database
echo "Creating default trackers in database..."
SQLITE_DB=/redmine/db/sqlite/redmine.db

# Only create trackers if they don't exist
TRACKER_COUNT=$(sqlite3 $SQLITE_DB "SELECT COUNT(*) FROM trackers;")
if [ "$TRACKER_COUNT" -eq "0" ]; then
  echo "No trackers found, creating default trackers..."
  
  # Create Bug tracker
  sqlite3 $SQLITE_DB "INSERT INTO trackers (name, description, default_status_id, is_in_roadmap, position) VALUES ('Bug', 'Software defects and issues', 1, 0, 1);"
  
  # Create Feature tracker
  sqlite3 $SQLITE_DB "INSERT INTO trackers (name, description, default_status_id, is_in_roadmap, position) VALUES ('Feature', 'New features and enhancements', 1, 1, 2);"
  
  # Create Support tracker
  sqlite3 $SQLITE_DB "INSERT INTO trackers (name, description, default_status_id, is_in_roadmap, position) VALUES ('Support', 'Support requests and questions', 1, 0, 3);"
  
  echo "Default trackers created!"
  
  # Associate trackers with all projects
  echo "Associating trackers with projects..."
  sqlite3 $SQLITE_DB "INSERT INTO projects_trackers SELECT p.id, t.id FROM projects p, trackers t;"
  
  # Add workflow permissions for all roles and trackers
  echo "Setting up workflow permissions..."
  sqlite3 $SQLITE_DB "INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id) SELECT t.id, r.id, NULL, s.id FROM trackers t, roles r, issue_statuses s;"
  
  echo "Workflow permissions created!"
fi

echo "Redmine configuration fixed successfully!"
