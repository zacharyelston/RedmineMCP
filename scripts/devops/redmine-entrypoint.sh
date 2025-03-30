#!/bin/bash
# Custom Redmine setup script to ensure proper permissions and initial configuration
set -e

echo "Running custom Redmine setup script..."

# Wait for Redmine to fully start
echo "Waiting for Redmine to be ready..."
sleep 10

# Ensure we're in the Redmine directory
cd /usr/src/redmine

# Enable REST API for all users
# This modifies the Redmine settings to enable API for all authentication modes
if [ -f config/configuration.yml ]; then
  echo "Configuring REST API access..."
  # Check if file already contains API configuration
  if ! grep -q "rest_api_enabled" config/configuration.yml; then
    # Add API configuration
    cat >> config/configuration.yml << EOF
production:
  rest_api_enabled: true
  jsonp_enabled: true
EOF
    echo "API access configured."
  else
    echo "API access already configured."
  fi
fi

# Create a default API access key for admin if needed
# This will be used for initial setup and testing
if [ -f /usr/src/redmine/log/production.log ]; then
  echo "Checking if admin API token exists..."
  ADMIN_TOKEN=$(grep -o "Admin API key: [a-zA-Z0-9]\+" /usr/src/redmine/log/production.log | head -1 | sed 's/Admin API key: //')
  
  if [ -z "$ADMIN_TOKEN" ]; then
    echo "No admin API token found, generating one..."
    
    # Use Ruby script to create admin token
    bundle exec rails runner "token = User.find(1).api_key; puts token.nil? ? 'No token found' : token"
    
    # Create API key for admin if needed
    bundle exec rails runner "user = User.find(1); if user.api_key.nil?; user.api_key = SecureRandom.hex(16); user.save; puts \"Created admin API key: #{user.api_key}\"; else; puts \"Admin API key already exists: #{user.api_key}\"; end"
  else
    echo "Admin API token already exists."
  fi
fi

# Create default trackers if they don't exist
echo "Creating default trackers if needed..."
bundle exec rails runner "
  ['Bug', 'Feature', 'Support'].each do |name|
    unless Tracker.exists?(name: name)
      t = Tracker.new(name: name, default_status_id: 1, is_in_roadmap: true)
      if t.save
        puts \"Created tracker: #{name}\"
      else
        puts \"Failed to create tracker #{name}: #{t.errors.full_messages.join(', ')}\"
      end
    else
      puts \"Tracker already exists: #{name}\"
    end
  end
"

# Set proper permissions for all projects
echo "Setting default permissions for all projects..."
bundle exec rails runner "
  Role.find_each do |role|
    unless role.permissions.include?(:manage_subtasks)
      role.permissions << :manage_subtasks
      role.save
      puts \"Added manage_subtasks permission to role: #{role.name}\"
    end
  end
"

echo "Custom Redmine setup completed successfully!"
exit 0
