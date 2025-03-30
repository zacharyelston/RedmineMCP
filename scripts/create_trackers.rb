puts "Starting tracker creation script..."

# Define default trackers
default_trackers = [
  { name: "Bug", description: "Software defects and issues", default_status_id: 1, is_in_roadmap: false },
  { name: "Feature", description: "New features and enhancements", default_status_id: 1, is_in_roadmap: true },
  { name: "Support", description: "Support requests and questions", default_status_id: 1, is_in_roadmap: false }
]

# Make sure we have at least one status
if IssueStatus.count == 0
  puts "Creating default issue status 'New'"
  IssueStatus.create(name: "New", is_closed: false, position: 1)
end

# Make sure we have at least one role
if Role.count == 0
  puts "Creating default role 'Manager'"
  Role.create(name: "Manager", position: 1, assignable: true, 
             permissions: [:add_project, :edit_project, :close_project, :select_project_modules, :manage_members, 
                          :manage_versions, :manage_categories, :view_issues, :add_issues, :edit_issues])
end

# Create trackers if they don't exist
existing_trackers = Tracker.all.map(&:name)
puts "Existing trackers: #{existing_trackers.join(', ')}"

default_trackers.each do |tracker_data|
  if existing_trackers.include?(tracker_data[:name])
    puts "Tracker already exists: #{tracker_data[:name]}"
  else
    puts "Creating tracker: #{tracker_data[:name]}"
    tracker = Tracker.new(
      name: tracker_data[:name],
      description: tracker_data[:description],
      default_status_id: tracker_data[:default_status_id],
      is_in_roadmap: tracker_data[:is_in_roadmap]
    )
    
    if tracker.save
      puts "✅ Successfully created tracker: #{tracker_data[:name]}"
      
      # Add this tracker to all projects
      Project.all.each do |project|
        puts "Adding tracker #{tracker_data[:name]} to project #{project.name}"
        project.trackers << tracker unless project.trackers.include?(tracker)
      end
      
      # Add default workflow permissions for Redmine 5.0
      # In Redmine 5.0, WorkflowRule is used instead of Workflow
      Role.all.each do |role|
        IssueStatus.all.each do |status|
          puts "Creating workflow rule for #{tracker_data[:name]}, role #{role.name}, status #{status.name}"
          # Create a workflow rule allowing the transition from any status to this status
          WorkflowRule.create(tracker_id: tracker.id, role_id: role.id, old_status_id: nil, new_status_id: status.id)
          # Create a workflow rule allowing the transition from this status to itself
          WorkflowRule.create(tracker_id: tracker.id, role_id: role.id, old_status_id: status.id, new_status_id: status.id)
        end
      end
    else
      puts "⚠️ Failed to create tracker #{tracker_data[:name]}: #{tracker.errors.full_messages.join(', ')}"
    end
  end
end

# Create a test project if none exists
if Project.count == 0
  puts "Creating a test project..."
  project = Project.new(
    name: "Test Project", 
    identifier: "test-project",
    description: "A test project created automatically",
    is_public: true
  )
  
  if project.save
    puts "✅ Created test project"
    
    # Add all trackers to the project
    Tracker.all.each do |tracker|
      project.trackers << tracker
    end
    project.save
  else
    puts "⚠️ Failed to create test project: #{project.errors.full_messages.join(', ')}"
  end
end

puts "Tracker creation script completed!"
