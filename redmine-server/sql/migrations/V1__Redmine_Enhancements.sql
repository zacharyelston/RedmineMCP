-- V1__Redmine_Enhancements.sql
-- Add custom fields, groups, and enhanced workflows to Redmine
-- Part of the ModelContextProtocol (MCP) Implementation

-- Create additional statuses
DO $$
BEGIN
  -- New status
  IF NOT EXISTS (SELECT 1 FROM issue_statuses WHERE name = 'New') THEN
    INSERT INTO issue_statuses (name, is_closed, position, default_done_ratio)
    VALUES ('New', FALSE, 1, NULL);
  END IF;

  -- In Progress status
  IF NOT EXISTS (SELECT 1 FROM issue_statuses WHERE name = 'In Progress') THEN
    INSERT INTO issue_statuses (name, is_closed, position, default_done_ratio)
    VALUES ('In Progress', FALSE, 2, NULL);
  END IF;

  -- Feedback status
  IF NOT EXISTS (SELECT 1 FROM issue_statuses WHERE name = 'Feedback') THEN
    INSERT INTO issue_statuses (name, is_closed, position, default_done_ratio)
    VALUES ('Feedback', FALSE, 3, NULL);
  END IF;

  -- Resolved status
  IF NOT EXISTS (SELECT 1 FROM issue_statuses WHERE name = 'Resolved') THEN
    INSERT INTO issue_statuses (name, is_closed, position, default_done_ratio)
    VALUES ('Resolved', FALSE, 4, NULL);
  END IF;

  -- Closed status
  IF NOT EXISTS (SELECT 1 FROM issue_statuses WHERE name = 'Closed') THEN
    INSERT INTO issue_statuses (name, is_closed, position, default_done_ratio)
    VALUES ('Closed', TRUE, 5, NULL);
  END IF;

  -- Rejected status
  IF NOT EXISTS (SELECT 1 FROM issue_statuses WHERE name = 'Rejected') THEN
    INSERT INTO issue_statuses (name, is_closed, position, default_done_ratio)
    VALUES ('Rejected', TRUE, 6, NULL);
  END IF;

  -- Blocked status
  IF NOT EXISTS (SELECT 1 FROM issue_statuses WHERE name = 'Blocked') THEN
    INSERT INTO issue_statuses (name, is_closed, position, default_done_ratio)
    VALUES ('Blocked', FALSE, 7, NULL);
  END IF;

  -- On Hold status
  IF NOT EXISTS (SELECT 1 FROM issue_statuses WHERE name = 'On Hold') THEN
    INSERT INTO issue_statuses (name, is_closed, position, default_done_ratio)
    VALUES ('On Hold', FALSE, 8, NULL);
  END IF;

  -- Ready for QA status
  IF NOT EXISTS (SELECT 1 FROM issue_statuses WHERE name = 'Ready for QA') THEN
    INSERT INTO issue_statuses (name, is_closed, position, default_done_ratio)
    VALUES ('Ready for QA', FALSE, 9, NULL);
  END IF;

  -- Verified status
  IF NOT EXISTS (SELECT 1 FROM issue_statuses WHERE name = 'Verified') THEN
    INSERT INTO issue_statuses (name, is_closed, position, default_done_ratio)
    VALUES ('Verified', FALSE, 10, NULL);
  END IF;
END $$;

-- Create trackers or ensure they exist
DO $$
BEGIN
  -- Bug tracker
  IF NOT EXISTS (SELECT 1 FROM trackers WHERE name = 'Bug') THEN
    INSERT INTO trackers (name, position, is_in_roadmap, fields_bits, description)
    VALUES ('Bug', 1, FALSE, 0, 'Bugs and defects that need to be fixed');
  ELSE
    UPDATE trackers SET description = 'Bugs and defects that need to be fixed' WHERE name = 'Bug';
  END IF;

  -- Feature tracker
  IF NOT EXISTS (SELECT 1 FROM trackers WHERE name = 'Feature') THEN
    INSERT INTO trackers (name, position, is_in_roadmap, fields_bits, description)
    VALUES ('Feature', 2, TRUE, 0, 'New features to be implemented');
  ELSE
    UPDATE trackers SET description = 'New features to be implemented' WHERE name = 'Feature';
  END IF;

  -- Support tracker
  IF NOT EXISTS (SELECT 1 FROM trackers WHERE name = 'Support') THEN
    INSERT INTO trackers (name, position, is_in_roadmap, fields_bits, description)
    VALUES ('Support', 3, FALSE, 0, 'Support requests from users');
  ELSE
    UPDATE trackers SET description = 'Support requests from users' WHERE name = 'Support';
  END IF;

  -- Task tracker
  IF NOT EXISTS (SELECT 1 FROM trackers WHERE name = 'Task') THEN
    INSERT INTO trackers (name, position, is_in_roadmap, fields_bits, description)
    VALUES ('Task', 4, TRUE, 0, 'Regular task to be completed');
  ELSE
    UPDATE trackers SET description = 'Regular task to be completed' WHERE name = 'Task';
  END IF;

  -- Epic tracker
  IF NOT EXISTS (SELECT 1 FROM trackers WHERE name = 'Epic') THEN
    INSERT INTO trackers (name, position, is_in_roadmap, fields_bits, description)
    VALUES ('Epic', 5, TRUE, 0, 'Large features that contain multiple stories');
  ELSE
    UPDATE trackers SET description = 'Large features that contain multiple stories' WHERE name = 'Epic';
  END IF;

  -- Story tracker
  IF NOT EXISTS (SELECT 1 FROM trackers WHERE name = 'Story') THEN
    INSERT INTO trackers (name, position, is_in_roadmap, fields_bits, description)
    VALUES ('Story', 6, TRUE, 0, 'User story describing functionality from user perspective');
  ELSE
    UPDATE trackers SET description = 'User story describing functionality from user perspective' WHERE name = 'Story';
  END IF;
END $$;

-- Create roles or ensure they exist
DO $$
BEGIN
  -- Manager role
  IF NOT EXISTS (SELECT 1 FROM roles WHERE name = 'Manager') THEN
    INSERT INTO roles (name, position, assignable, builtin, permissions, issues_visibility, users_visibility, time_entries_visibility, all_roles_managed, settings)
    VALUES ('Manager', 1, TRUE, 0, '---
- :add_project
- :edit_project
- :close_project
- :select_project_modules
- :manage_members
- :manage_versions
- :add_subprojects
- :manage_public_queries
- :save_queries
- :view_issues
- :add_issues
- :edit_issues
- :copy_issues
- :manage_issue_relations
- :manage_subtasks
- :set_issues_private
- :set_own_issues_private
- :add_issue_notes
- :edit_issue_notes
- :edit_own_issue_notes
- :view_private_notes
- :set_notes_private
- :move_issues
- :delete_issues
- :manage_categories
- :view_time_entries
- :log_time
- :edit_time_entries
- :edit_own_time_entries
- :manage_project_activities
- :manage_news
- :comment_news
- :add_documents
- :edit_documents
- :delete_documents
- :view_documents
- :manage_files
- :view_files
- :view_gantt
- :view_calendar
- :view_wiki_pages
- :view_wiki_edits
- :export_wiki_pages
- :edit_wiki_pages
- :delete_wiki_pages
- :delete_wiki_pages_attachments
- :protect_wiki_pages
- :manage_wiki
- :manage_repository
- :browse_repository
- :view_changesets
- :commit_access
- :manage_related_issues
- :manage_boards
- :add_messages
- :edit_messages
- :edit_own_messages
- :delete_messages
- :delete_own_messages
- :view_message_watchers
- :add_message_watchers
- :delete_message_watchers
- :manage_modules', 'all', 'all', 'all', TRUE, '--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess
permissions_all_trackers: !ruby/hash:ActiveSupport::HashWithIndifferentAccess
  view_issues: ''1''
  add_issues: ''1''
  edit_issues: ''1''
  add_issue_notes: ''1''
  delete_issues: ''1''
permissions_tracker_ids: !ruby/hash:ActiveSupport::HashWithIndifferentAccess
  view_issues: []
  add_issues: []
  edit_issues: []
  add_issue_notes: []
  delete_issues: []');
  END IF;

  -- Developer role
  IF NOT EXISTS (SELECT 1 FROM roles WHERE name = 'Developer') THEN
    INSERT INTO roles (name, position, assignable, builtin, permissions, issues_visibility, users_visibility, time_entries_visibility, all_roles_managed, settings)
    VALUES ('Developer', 2, TRUE, 0, '---
- :manage_versions
- :manage_categories
- :view_issues
- :add_issues
- :edit_issues
- :view_private_notes
- :set_notes_private
- :move_issues
- :delete_issues
- :manage_issue_relations
- :manage_subtasks
- :add_issue_notes
- :save_queries
- :view_gantt
- :view_calendar
- :log_time
- :view_time_entries
- :view_wiki_pages
- :view_wiki_edits
- :edit_wiki_pages
- :delete_wiki_pages
- :view_messages
- :add_messages
- :edit_own_messages
- :view_files
- :manage_files
- :browse_repository
- :view_changesets
- :commit_access
- :manage_related_issues', 'default', 'all', 'all', FALSE, '--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess
permissions_all_trackers: !ruby/hash:ActiveSupport::HashWithIndifferentAccess
  view_issues: ''1''
  add_issues: ''1''
  edit_issues: ''1''
  add_issue_notes: ''1''
  delete_issues: ''1''
permissions_tracker_ids: !ruby/hash:ActiveSupport::HashWithIndifferentAccess
  view_issues: []
  add_issues: []
  edit_issues: []
  add_issue_notes: []
  delete_issues: []');
  END IF;

  -- Reporter role
  IF NOT EXISTS (SELECT 1 FROM roles WHERE name = 'Reporter') THEN
    INSERT INTO roles (name, position, assignable, builtin, permissions, issues_visibility, users_visibility, time_entries_visibility, all_roles_managed, settings)
    VALUES ('Reporter', 3, TRUE, 0, '---
- :view_issues
- :add_issues
- :add_issue_notes
- :save_queries
- :view_gantt
- :view_calendar
- :log_time
- :view_time_entries
- :view_wiki_pages
- :view_wiki_edits
- :view_messages
- :add_messages
- :edit_own_messages
- :view_files
- :browse_repository
- :view_changesets', 'default', 'all', 'all', FALSE, '--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess
permissions_all_trackers: !ruby/hash:ActiveSupport::HashWithIndifferentAccess
  view_issues: ''1''
  add_issues: ''1''
  edit_issues: ''0''
  add_issue_notes: ''1''
  delete_issues: ''0''
permissions_tracker_ids: !ruby/hash:ActiveSupport::HashWithIndifferentAccess
  view_issues: []
  add_issues: []
  edit_issues: []
  add_issue_notes: []
  delete_issues: []');
  END IF;
END $$;

-- Create default project if not exists
DO $$
DECLARE
  v_project_id INTEGER;
BEGIN
  -- Create the default project if it doesn't exist
  IF NOT EXISTS (SELECT 1 FROM projects WHERE identifier = 'mcp-project') THEN
    INSERT INTO projects (
      name, description, homepage, is_public, 
      parent_id, created_on, updated_on, 
      identifier, status, lft, rgt, 
      inherit_members, default_version_id, default_assigned_to_id
    )
    VALUES (
      'MCP Project', 'Main project for Model Context Protocol', '', TRUE,
      NULL, NOW(), NOW(),
      'mcp-project', 1, 1, 2,
      FALSE, NULL, NULL
    )
    RETURNING id INTO v_project_id;

    -- Enable modules
    INSERT INTO enabled_modules (project_id, name)
    VALUES
      (v_project_id, 'issue_tracking'),
      (v_project_id, 'time_tracking'),
      (v_project_id, 'news'),
      (v_project_id, 'documents'),
      (v_project_id, 'files'),
      (v_project_id, 'wiki'),
      (v_project_id, 'repository'),
      (v_project_id, 'boards'),
      (v_project_id, 'calendar'),
      (v_project_id, 'gantt');
  ELSE
    -- Get the project ID
    SELECT id INTO v_project_id FROM projects WHERE identifier = 'mcp-project';
  END IF;

  -- Associate all trackers with the project
  IF v_project_id IS NOT NULL THEN
    INSERT INTO projects_trackers (project_id, tracker_id)
    SELECT v_project_id, id
    FROM trackers
    WHERE id NOT IN (
      SELECT tracker_id FROM projects_trackers WHERE project_id = v_project_id
    );
  END IF;
END $$;

-- Ensure we have API keys set up correctly for admin user
DO $$
DECLARE 
  admin_user_id INTEGER;
BEGIN
  -- Get admin user ID
  SELECT id INTO admin_user_id FROM users WHERE login = 'admin';

  IF admin_user_id IS NOT NULL THEN
    -- Check if admin user has an API token
    IF EXISTS (SELECT 1 FROM tokens WHERE user_id = admin_user_id AND action = 'api') THEN
      -- Update the token to match our predefined value
      UPDATE tokens 
      SET value = '7a4ed5c91b405d30fda60909dbc86c2651c38217', 
          updated_on = NOW() 
      WHERE user_id = admin_user_id AND action = 'api';
    ELSE
      -- Create API token for admin user
      INSERT INTO tokens (user_id, action, value, created_on, updated_on)
      VALUES (admin_user_id, 'api', '7a4ed5c91b405d30fda60909dbc86c2651c38217', NOW(), NOW());
    END IF;
  END IF;
END $$;

-- Create additional users with API keys
DO $$
DECLARE
  v_user_id INTEGER;
  v_project_id INTEGER;
  v_dev_role_id INTEGER;
  v_reporter_role_id INTEGER;
  v_manager_role_id INTEGER;
BEGIN
  -- Get project ID
  SELECT id INTO v_project_id FROM projects WHERE identifier = 'mcp-project';
  
  -- Get role IDs
  SELECT id INTO v_dev_role_id FROM roles WHERE name = 'Developer';
  SELECT id INTO v_reporter_role_id FROM roles WHERE name = 'Reporter';
  SELECT id INTO v_manager_role_id FROM roles WHERE name = 'Manager';

  -- Create test user (if not exists)
  IF NOT EXISTS (SELECT 1 FROM users WHERE login = 'testuser') THEN
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, language, created_on, updated_on, type)
    VALUES ('testuser', 'b5e7f32ca69ce41eba093d31546d6a5e0c778693', 'Test', 'User', FALSE, 1, 'en', NOW(), NOW(), 'User')
    RETURNING id INTO v_user_id;
    
    -- Create email for the new user
    INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
    VALUES (v_user_id, 'test@example.com', TRUE, TRUE, NOW(), NOW());
    
    -- Create API key for the new user
    INSERT INTO tokens (user_id, action, value, created_on, updated_on)
    VALUES (v_user_id, 'api', '3e9b7b22b84a26e7e95b3d73b6e65f6c3fe6e3f0', NOW(), NOW());
    
    -- Assign to project with Reporter role
    IF v_project_id IS NOT NULL AND v_reporter_role_id IS NOT NULL THEN
      INSERT INTO members (user_id, project_id, created_on)
      VALUES (v_user_id, v_project_id, NOW());
      
      INSERT INTO member_roles (member_id, role_id)
      SELECT id, v_reporter_role_id
      FROM members
      WHERE user_id = v_user_id AND project_id = v_project_id;
    END IF;
  END IF;

  -- Create developer user (if not exists)
  IF NOT EXISTS (SELECT 1 FROM users WHERE login = 'developer') THEN
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, language, created_on, updated_on, type)
    VALUES ('developer', 'b5e7f32ca69ce41eba093d31546d6a5e0c778693', 'Dev', 'User', FALSE, 1, 'en', NOW(), NOW(), 'User')
    RETURNING id INTO v_user_id;
    
    -- Create email for the new user
    INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
    VALUES (v_user_id, 'dev@example.com', TRUE, TRUE, NOW(), NOW());
    
    -- Create API key for the new user
    INSERT INTO tokens (user_id, action, value, created_on, updated_on)
    VALUES (v_user_id, 'api', 'f91c59b0d78f2a10d9b7ea3c631d9f2cbba94f8f', NOW(), NOW());
    
    -- Assign to project with Developer role
    IF v_project_id IS NOT NULL AND v_dev_role_id IS NOT NULL THEN
      INSERT INTO members (user_id, project_id, created_on)
      VALUES (v_user_id, v_project_id, NOW());
      
      INSERT INTO member_roles (member_id, role_id)
      SELECT id, v_dev_role_id
      FROM members
      WHERE user_id = v_user_id AND project_id = v_project_id;
    END IF;
  END IF;

  -- Create manager user (if not exists)
  IF NOT EXISTS (SELECT 1 FROM users WHERE login = 'manager') THEN
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, language, created_on, updated_on, type)
    VALUES ('manager', 'b5e7f32ca69ce41eba093d31546d6a5e0c778693', 'Project', 'Manager', FALSE, 1, 'en', NOW(), NOW(), 'User')
    RETURNING id INTO v_user_id;
    
    -- Create email for the new user
    INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
    VALUES (v_user_id, 'manager@example.com', TRUE, TRUE, NOW(), NOW());
    
    -- Create API key for the new user
    INSERT INTO tokens (user_id, action, value, created_on, updated_on)
    VALUES (v_user_id, 'api', '5c98f85a9f2e34c3b217758e910e196c7a77bf5b', NOW(), NOW());
    
    -- Assign to project with Manager role
    IF v_project_id IS NOT NULL AND v_manager_role_id IS NOT NULL THEN
      INSERT INTO members (user_id, project_id, created_on)
      VALUES (v_user_id, v_project_id, NOW());
      
      INSERT INTO member_roles (member_id, role_id)
      SELECT id, v_manager_role_id
      FROM members
      WHERE user_id = v_user_id AND project_id = v_project_id;
    END IF;
  END IF;
END $$;

-- Create custom field formats if they don't exist
DO $$
BEGIN
  INSERT INTO custom_field_formats (name)
  SELECT 'string' WHERE NOT EXISTS (SELECT 1 FROM custom_field_formats WHERE name = 'string');

  INSERT INTO custom_field_formats (name)
  SELECT 'text' WHERE NOT EXISTS (SELECT 1 FROM custom_field_formats WHERE name = 'text');

  INSERT INTO custom_field_formats (name)
  SELECT 'int' WHERE NOT EXISTS (SELECT 1 FROM custom_field_formats WHERE name = 'int');

  INSERT INTO custom_field_formats (name)
  SELECT 'float' WHERE NOT EXISTS (SELECT 1 FROM custom_field_formats WHERE name = 'float');

  INSERT INTO custom_field_formats (name)
  SELECT 'list' WHERE NOT EXISTS (SELECT 1 FROM custom_field_formats WHERE name = 'list');

  INSERT INTO custom_field_formats (name)
  SELECT 'date' WHERE NOT EXISTS (SELECT 1 FROM custom_field_formats WHERE name = 'date');

  INSERT INTO custom_field_formats (name)
  SELECT 'bool' WHERE NOT EXISTS (SELECT 1 FROM custom_field_formats WHERE name = 'bool');

  INSERT INTO custom_field_formats (name)
  SELECT 'user' WHERE NOT EXISTS (SELECT 1 FROM custom_field_formats WHERE name = 'user');

  INSERT INTO custom_field_formats (name)
  SELECT 'version' WHERE NOT EXISTS (SELECT 1 FROM custom_field_formats WHERE name = 'version');
END $$;

-- Create Custom Fields
DO $$
DECLARE
  v_format_string_id INTEGER;
  v_format_int_id INTEGER;
  v_format_date_id INTEGER;
  v_format_list_id INTEGER;
  v_format_bool_id INTEGER;
  v_format_text_id INTEGER;
  v_format_user_id INTEGER;
  v_custom_field_id INTEGER;
  v_tracker_bug_id INTEGER;
  v_tracker_feature_id INTEGER;
  v_tracker_task_id INTEGER;
  v_tracker_support_id INTEGER;
  v_project_id INTEGER;
BEGIN
  -- Get format IDs
  SELECT id INTO v_format_string_id FROM custom_field_formats WHERE name = 'string';
  SELECT id INTO v_format_int_id FROM custom_field_formats WHERE name = 'int';
  SELECT id INTO v_format_date_id FROM custom_field_formats WHERE name = 'date';
  SELECT id INTO v_format_list_id FROM custom_field_formats WHERE name = 'list';
  SELECT id INTO v_format_bool_id FROM custom_field_formats WHERE name = 'bool';
  SELECT id INTO v_format_text_id FROM custom_field_formats WHERE name = 'text';
  SELECT id INTO v_format_user_id FROM custom_field_formats WHERE name = 'user';
  
  -- Get tracker IDs
  SELECT id INTO v_tracker_bug_id FROM trackers WHERE name = 'Bug';
  SELECT id INTO v_tracker_feature_id FROM trackers WHERE name = 'Feature';
  SELECT id INTO v_tracker_task_id FROM trackers WHERE name = 'Task';
  SELECT id INTO v_tracker_support_id FROM trackers WHERE name = 'Support';

  -- Get project ID
  SELECT id INTO v_project_id FROM projects WHERE identifier = 'mcp-project';

  -- 1. Severity custom field (for bug tracker)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'Severity') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'IssueCustomField', 'Severity', 'list', 
      E'Critical\nHigh\nMedium\nLow', 
      '', NULL, NULL, FALSE, TRUE, TRUE, 
      1, TRUE, 'Medium', TRUE, '{}', 'The severity level of the bug',
      TRUE
    )
    RETURNING id INTO v_custom_field_id;

    -- Associate with Bug tracker
    IF v_tracker_bug_id IS NOT NULL AND v_custom_field_id IS NOT NULL THEN
      INSERT INTO custom_fields_trackers (custom_field_id, tracker_id)
      VALUES (v_custom_field_id, v_tracker_bug_id);
    END IF;
  END IF;

  -- 2. Story Points custom field (for Feature and Task trackers)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'Story Points') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'IssueCustomField', 'Story Points', 'int', 
      NULL, 
      '', NULL, NULL, FALSE, TRUE, TRUE, 
      2, TRUE, '', TRUE, '{}', 'Estimated effort in story points (Fibonacci: 1,2,3,5,8,13)',
      TRUE
    )
    RETURNING id INTO v_custom_field_id;

    -- Associate with Feature tracker
    IF v_tracker_feature_id IS NOT NULL AND v_custom_field_id IS NOT NULL THEN
      INSERT INTO custom_fields_trackers (custom_field_id, tracker_id)
      VALUES (v_custom_field_id, v_tracker_feature_id);
    END IF;

    -- Associate with Task tracker
    IF v_tracker_task_id IS NOT NULL AND v_custom_field_id IS NOT NULL THEN
      INSERT INTO custom_fields_trackers (custom_field_id, tracker_id)
      VALUES (v_custom_field_id, v_tracker_task_id);
    END IF;
  END IF;

  -- 3. Target Date (customized display date for all issues)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'Target Date') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'IssueCustomField', 'Target Date', 'date', 
      NULL, 
      '', NULL, NULL, FALSE, TRUE, TRUE, 
      3, TRUE, '', TRUE, '{}', 'Target completion date',
      TRUE
    );
  END IF;

  -- 4. Environment custom field (for bug tracker)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'Environment') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'IssueCustomField', 'Environment', 'text', 
      NULL, 
      '', NULL, NULL, FALSE, TRUE, FALSE, 
      4, TRUE, '', TRUE, '{}', 'Environment details (OS, browser, etc.)',
      TRUE
    )
    RETURNING id INTO v_custom_field_id;

    -- Associate with Bug tracker
    IF v_tracker_bug_id IS NOT NULL AND v_custom_field_id IS NOT NULL THEN
      INSERT INTO custom_fields_trackers (custom_field_id, tracker_id)
      VALUES (v_custom_field_id, v_tracker_bug_id);
    END IF;
  END IF;

  -- 5. Support Category (for support tickets)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'Support Category') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'IssueCustomField', 'Support Category', 'list', 
      E'Technical\nAccess\nAccount\nBilling\nUsage\nOther', 
      '', NULL, NULL, FALSE, TRUE, FALSE, 
      5, TRUE, 'Technical', TRUE, '{}', 'Category of support request',
      TRUE
    )
    RETURNING id INTO v_custom_field_id;

    -- Associate with Support tracker
    IF v_tracker_support_id IS NOT NULL AND v_custom_field_id IS NOT NULL THEN
      INSERT INTO custom_fields_trackers (custom_field_id, tracker_id)
      VALUES (v_custom_field_id, v_tracker_support_id);
    END IF;
  END IF;

  -- 6. Affects Version (for bug tracker)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'Affects Version') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'IssueCustomField', 'Affects Version', 'string', 
      NULL, 
      '', NULL, NULL, FALSE, TRUE, FALSE, 
      6, TRUE, '', TRUE, '{}', 'Version where the bug was found',
      TRUE
    )
    RETURNING id INTO v_custom_field_id;

    -- Associate with Bug tracker
    IF v_tracker_bug_id IS NOT NULL AND v_custom_field_id IS NOT NULL THEN
      INSERT INTO custom_fields_trackers (custom_field_id, tracker_id)
      VALUES (v_custom_field_id, v_tracker_bug_id);
    END IF;
  END IF;

  -- 7. QA Approved (for bug and feature trackers)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'QA Approved') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'IssueCustomField', 'QA Approved', 'bool', 
      NULL, 
      '', NULL, NULL, FALSE, TRUE, FALSE, 
      7, TRUE, '0', TRUE, '{}', 'Approved by QA',
      TRUE
    )
    RETURNING id INTO v_custom_field_id;

    -- Associate with Bug tracker
    IF v_tracker_bug_id IS NOT NULL AND v_custom_field_id IS NOT NULL THEN
      INSERT INTO custom_fields_trackers (custom_field_id, tracker_id)
      VALUES (v_custom_field_id, v_tracker_bug_id);
    END IF;

    -- Associate with Feature tracker
    IF v_tracker_feature_id IS NOT NULL AND v_custom_field_id IS NOT NULL THEN
      INSERT INTO custom_fields_trackers (custom_field_id, tracker_id)
      VALUES (v_custom_field_id, v_tracker_feature_id);
    END IF;
  END IF;

  -- 8. Department (user custom field)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'Department') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'UserCustomField', 'Department', 'list', 
      E'Engineering\nQA\nSupport\nProduct\nMarketing\nSales\nManagement', 
      '', NULL, NULL, FALSE, TRUE, TRUE, 
      1, TRUE, 'Engineering', TRUE, '{}', 'Department the user belongs to',
      TRUE
    );
  END IF;

  -- 9. Project Priority (project custom field)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'Project Priority') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'ProjectCustomField', 'Project Priority', 'list', 
      E'Critical\nHigh\nMedium\nLow', 
      '', NULL, NULL, FALSE, TRUE, TRUE, 
      1, TRUE, 'Medium', TRUE, '{}', 'Priority level of the project',
      TRUE
    );
  END IF;

  -- 10. Project Lead (project custom field)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'Project Lead') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'ProjectCustomField', 'Project Lead', 'user', 
      NULL, 
      '', NULL, NULL, FALSE, TRUE, TRUE, 
      2, TRUE, '', TRUE, '{}', 'Lead person responsible for the project',
      TRUE
    );
  END IF;
END $$;

-- Create User Groups
DO $$
DECLARE
  v_group_id INTEGER;
  v_user_id INTEGER;
  v_dev_role_id INTEGER;
  v_manager_role_id INTEGER;
  v_reporter_role_id INTEGER;
  v_project_id INTEGER;
BEGIN
  -- Get role IDs
  SELECT id INTO v_dev_role_id FROM roles WHERE name = 'Developer';
  SELECT id INTO v_manager_role_id FROM roles WHERE name = 'Manager';
  SELECT id INTO v_reporter_role_id FROM roles WHERE name = 'Reporter';
  
  -- Get project ID
  SELECT id INTO v_project_id FROM projects WHERE identifier = 'mcp-project';

  -- Create Developers group
  IF NOT EXISTS (SELECT 1 FROM users WHERE type = 'Group' AND lastname = 'Developers') THEN
    -- Create the group
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, type, created_on, updated_on)
    VALUES ('', '', '', 'Developers', FALSE, 1, 'Group', NOW(), NOW())
    RETURNING id INTO v_group_id;
    
    -- Add developer user to the group if exists
    SELECT id INTO v_user_id FROM users WHERE login = 'developer' AND type = 'User';
    IF v_user_id IS NOT NULL AND v_group_id IS NOT NULL THEN
      INSERT INTO groups_users (group_id, user_id)
      VALUES (v_group_id, v_user_id);
    END IF;
    
    -- Assign group to project with Developer role
    IF v_dev_role_id IS NOT NULL AND v_project_id IS NOT NULL AND v_group_id IS NOT NULL THEN
      -- Create member for group
      INSERT INTO members (user_id, project_id, created_on)
      VALUES (v_group_id, v_project_id, NOW())
      ON CONFLICT DO NOTHING;
      
      -- Assign role to member
      INSERT INTO member_roles (member_id, role_id)
      SELECT m.id, v_dev_role_id
      FROM members m
      WHERE m.user_id = v_group_id AND m.project_id = v_project_id
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;

  -- Create Managers group
  IF NOT EXISTS (SELECT 1 FROM users WHERE type = 'Group' AND lastname = 'Managers') THEN
    -- Create the group
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, type, created_on, updated_on)
    VALUES ('', '', '', 'Managers', FALSE, 1, 'Group', NOW(), NOW())
    RETURNING id INTO v_group_id;
    
    -- Add manager user to the group if exists
    SELECT id INTO v_user_id FROM users WHERE login = 'manager' AND type = 'User';
    IF v_user_id IS NOT NULL AND v_group_id IS NOT NULL THEN
      INSERT INTO groups_users (group_id, user_id)
      VALUES (v_group_id, v_user_id);
    END IF;
    
    -- Assign group to project with Manager role
    IF v_manager_role_id IS NOT NULL AND v_project_id IS NOT NULL AND v_group_id IS NOT NULL THEN
      -- Create member for group
      INSERT INTO members (user_id, project_id, created_on)
      VALUES (v_group_id, v_project_id, NOW())
      ON CONFLICT DO NOTHING;
      
      -- Assign role to member
      INSERT INTO member_roles (member_id, role_id)
      SELECT m.id, v_manager_role_id
      FROM members m
      WHERE m.user_id = v_group_id AND m.project_id = v_project_id
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;

  -- Create QA Team group
  IF NOT EXISTS (SELECT 1 FROM users WHERE type = 'Group' AND lastname = 'QA Team') THEN
    -- Create the group
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, type, created_on, updated_on)
    VALUES ('', '', '', 'QA Team', FALSE, 1, 'Group', NOW(), NOW())
    RETURNING id INTO v_group_id;
    
    -- Assign group to project with Reporter role
    IF v_reporter_role_id IS NOT NULL AND v_project_id IS NOT NULL AND v_group_id IS NOT NULL THEN
      -- Create member for group
      INSERT INTO members (user_id, project_id, created_on)
      VALUES (v_group_id, v_project_id, NOW())
      ON CONFLICT DO NOTHING;
      
      -- Assign role to member
      INSERT INTO member_roles (member_id, role_id)
      SELECT m.id, v_reporter_role_id
      FROM members m
      WHERE m.user_id = v_group_id AND m.project_id = v_project_id
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;

  -- Create Support Team group
  IF NOT EXISTS (SELECT 1 FROM users WHERE type = 'Group' AND lastname = 'Support Team') THEN
    -- Create the group
    INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, type, created_on, updated_on)
    VALUES ('', '', '', 'Support Team', FALSE, 1, 'Group', NOW(), NOW())
    RETURNING id INTO v_group_id;
    
    -- Assign group to project with Reporter role
    IF v_reporter_role_id IS NOT NULL AND v_project_id IS NOT NULL AND v_group_id IS NOT NULL THEN
      -- Create member for group
      INSERT INTO members (user_id, project_id, created_on)
      VALUES (v_group_id, v_project_id, NOW())
      ON CONFLICT DO NOTHING;
      
      -- Assign role to member
      INSERT INTO member_roles (member_id, role_id)
      SELECT m.id, v_reporter_role_id
      FROM members m
      WHERE m.user_id = v_group_id AND m.project_id = v_project_id
      ON CONFLICT DO NOTHING;
    END IF;
  END IF;
END $$;

-- Define workflow transitions
DO $$
DECLARE
  v_new_id INTEGER;
  v_in_progress_id INTEGER;
  v_feedback_id INTEGER;
  v_resolved_id INTEGER;
  v_closed_id INTEGER;
  v_rejected_id INTEGER;
  v_blocked_id INTEGER;
  v_on_hold_id INTEGER;
  v_ready_for_qa_id INTEGER;
  v_verified_id INTEGER;
  v_bug_id INTEGER;
  v_feature_id INTEGER;
  v_support_id INTEGER;
  v_task_id INTEGER;
  v_epic_id INTEGER;
  v_story_id INTEGER;
  v_dev_role_id INTEGER;
  v_manager_role_id INTEGER;
  v_reporter_role_id INTEGER;
BEGIN
  -- Get status IDs
  SELECT id INTO v_new_id FROM issue_statuses WHERE name = 'New';
  SELECT id INTO v_in_progress_id FROM issue_statuses WHERE name = 'In Progress';
  SELECT id INTO v_feedback_id FROM issue_statuses WHERE name = 'Feedback';
  SELECT id INTO v_resolved_id FROM issue_statuses WHERE name = 'Resolved';
  SELECT id INTO v_closed_id FROM issue_statuses WHERE name = 'Closed';
  SELECT id INTO v_rejected_id FROM issue_statuses WHERE name = 'Rejected';
  SELECT id INTO v_blocked_id FROM issue_statuses WHERE name = 'Blocked';
  SELECT id INTO v_on_hold_id FROM issue_statuses WHERE name = 'On Hold';
  SELECT id INTO v_ready_for_qa_id FROM issue_statuses WHERE name = 'Ready for QA';
  SELECT id INTO v_verified_id FROM issue_statuses WHERE name = 'Verified';
  
  -- Get tracker IDs
  SELECT id INTO v_bug_id FROM trackers WHERE name = 'Bug';
  SELECT id INTO v_feature_id FROM trackers WHERE name = 'Feature';
  SELECT id INTO v_support_id FROM trackers WHERE name = 'Support';
  SELECT id INTO v_task_id FROM trackers WHERE name = 'Task';
  SELECT id INTO v_epic_id FROM trackers WHERE name = 'Epic';
  SELECT id INTO v_story_id FROM trackers WHERE name = 'Story';

  -- Get role IDs
  SELECT id INTO v_dev_role_id FROM roles WHERE name = 'Developer';
  SELECT id INTO v_manager_role_id FROM roles WHERE name = 'Manager';
  SELECT id INTO v_reporter_role_id FROM roles WHERE name = 'Reporter';

  -- Define workflows for each tracker and role
  -- For Bug tracker
  IF v_bug_id IS NOT NULL THEN
    -- Developer role bug workflow
    IF v_dev_role_id IS NOT NULL THEN
      -- New -> In Progress transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_bug_id AND role_id = v_dev_role_id AND old_status_id = v_new_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_bug_id, v_dev_role_id, v_new_id, v_in_progress_id);
      END IF;
      
      -- In Progress -> Resolved transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_bug_id AND role_id = v_dev_role_id AND old_status_id = v_in_progress_id AND new_status_id = v_resolved_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_bug_id, v_dev_role_id, v_in_progress_id, v_resolved_id);
      END IF;
      
      -- In Progress -> Feedback transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_bug_id AND role_id = v_dev_role_id AND old_status_id = v_in_progress_id AND new_status_id = v_feedback_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_bug_id, v_dev_role_id, v_in_progress_id, v_feedback_id);
      END IF;
      
      -- Feedback -> In Progress transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_bug_id AND role_id = v_dev_role_id AND old_status_id = v_feedback_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_bug_id, v_dev_role_id, v_feedback_id, v_in_progress_id);
      END IF;
      
      -- In Progress -> Blocked
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_bug_id AND role_id = v_dev_role_id AND old_status_id = v_in_progress_id AND new_status_id = v_blocked_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_bug_id, v_dev_role_id, v_in_progress_id, v_blocked_id);
      END IF;
      
      -- Blocked -> In Progress
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_bug_id AND role_id = v_dev_role_id AND old_status_id = v_blocked_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_bug_id, v_dev_role_id, v_blocked_id, v_in_progress_id);
      END IF;
      
      -- In Progress -> Ready for QA
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_bug_id AND role_id = v_dev_role_id AND old_status_id = v_in_progress_id AND new_status_id = v_ready_for_qa_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_bug_id, v_dev_role_id, v_in_progress_id, v_ready_for_qa_id);
      END IF;
      
      -- Ready for QA -> In Progress
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_bug_id AND role_id = v_dev_role_id AND old_status_id = v_ready_for_qa_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_bug_id, v_dev_role_id, v_ready_for_qa_id, v_in_progress_id);
      END IF;
    END IF;

    -- Manager role bug workflow
    IF v_manager_role_id IS NOT NULL THEN
      -- New -> In Progress transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_bug_id AND role_id = v_manager_role_id AND old_status_id = v_new_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_bug_id, v_manager_role_id, v_new_id, v_in_progress_id);
      END IF;
      
      -- New -> Rejected transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_bug_id AND role_id = v_manager_role_id AND old_status_id = v_new_id AND new_status_id = v_rejected_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_bug_id, v_manager_role_id, v_new_id, v_rejected_id);
      END IF;
      
      -- Resolved -> Closed transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_bug_id AND role_id = v_manager_role_id AND old_status_id = v_resolved_id AND new_status_id = v_closed_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_bug_id, v_manager_role_id, v_resolved_id, v_closed_id);
      END IF;
      
      -- Resolved -> Feedback transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_bug_id AND role_id = v_manager_role_id AND old_status_id = v_resolved_id AND new_status_id = v_feedback_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_bug_id, v_manager_role_id, v_resolved_id, v_feedback_id);
      END IF;
      
      -- New -> On Hold
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_bug_id AND role_id = v_manager_role_id AND old_status_id = v_new_id AND new_status_id = v_on_hold_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_bug_id, v_manager_role_id, v_new_id, v_on_hold_id);
      END IF;
      
      -- On Hold -> New
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_bug_id AND role_id = v_manager_role_id AND old_status_id = v_on_hold_id AND new_status_id = v_new_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_bug_id, v_manager_role_id, v_on_hold_id, v_new_id);
      END IF;
      
      -- Verified -> Closed
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_bug_id AND role_id = v_manager_role_id AND old_status_id = v_verified_id AND new_status_id = v_closed_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_bug_id, v_manager_role_id, v_verified_id, v_closed_id);
      END IF;
    END IF;

    -- Reporter role bug workflow
    IF v_reporter_role_id IS NOT NULL THEN
      -- Resolved -> Closed transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_bug_id AND role_id = v_reporter_role_id AND old_status_id = v_resolved_id AND new_status_id = v_closed_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_bug_id, v_reporter_role_id, v_resolved_id, v_closed_id);
      END IF;
      
      -- Resolved -> Feedback transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_bug_id AND role_id = v_reporter_role_id AND old_status_id = v_resolved_id AND new_status_id = v_feedback_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_bug_id, v_reporter_role_id, v_resolved_id, v_feedback_id);
      END IF;
      
      -- Ready for QA -> Verified
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_bug_id AND role_id = v_reporter_role_id AND old_status_id = v_ready_for_qa_id AND new_status_id = v_verified_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_bug_id, v_reporter_role_id, v_ready_for_qa_id, v_verified_id);
      END IF;
      
      -- Ready for QA -> In Progress
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_bug_id AND role_id = v_reporter_role_id AND old_status_id = v_ready_for_qa_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_bug_id, v_reporter_role_id, v_ready_for_qa_id, v_in_progress_id);
      END IF;
    END IF;
  END IF;

  -- For Feature tracker - Similar transitions to Bug tracker
  IF v_feature_id IS NOT NULL THEN
    FOR v_role_id IN 
      SELECT id FROM roles WHERE id IN (v_dev_role_id, v_manager_role_id, v_reporter_role_id)
    LOOP
      -- Apply same workflows as Bug tracker
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      SELECT v_feature_id, v_role_id, old_status_id, new_status_id
      FROM workflows
      WHERE tracker_id = v_bug_id AND role_id = v_role_id
      ON CONFLICT DO NOTHING;
    END LOOP;
  END IF;

  -- Workflows for support tracker
  -- Developer and manager workflows for support issues
  FOR v_role_id IN 
    SELECT id FROM roles WHERE id IN (v_dev_role_id, v_manager_role_id)
  LOOP
    -- New -> In Progress
    IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_support_id AND role_id = v_role_id AND old_status_id = v_new_id AND new_status_id = v_in_progress_id) THEN
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      VALUES (v_support_id, v_role_id, v_new_id, v_in_progress_id);
    END IF;
    
    -- New -> Feedback
    IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_support_id AND role_id = v_role_id AND old_status_id = v_new_id AND new_status_id = v_feedback_id) THEN
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      VALUES (v_support_id, v_role_id, v_new_id, v_feedback_id);
    END IF;
    
    -- In Progress -> Resolved
    IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_support_id AND role_id = v_role_id AND old_status_id = v_in_progress_id AND new_status_id = v_resolved_id) THEN
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      VALUES (v_support_id, v_role_id, v_in_progress_id, v_resolved_id);
    END IF;
    
    -- Feedback -> In Progress
    IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_support_id AND role_id = v_role_id AND old_status_id = v_feedback_id AND new_status_id = v_in_progress_id) THEN
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      VALUES (v_support_id, v_role_id, v_feedback_id, v_in_progress_id);
    END IF;
    
    -- Resolved -> Closed
    IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_support_id AND role_id = v_role_id AND old_status_id = v_resolved_id AND new_status_id = v_closed_id) THEN
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      VALUES (v_support_id, v_role_id, v_resolved_id, v_closed_id);
    END IF;
  END LOOP;

  -- Reporter role support workflow
  IF v_reporter_role_id IS NOT NULL THEN
    -- New -> Feedback
    IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_support_id AND role_id = v_reporter_role_id AND old_status_id = v_new_id AND new_status_id = v_feedback_id) THEN
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      VALUES (v_support_id, v_reporter_role_id, v_new_id, v_feedback_id);
    END IF;
    
    -- Resolved -> Closed
    IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_support_id AND role_id = v_reporter_role_id AND old_status_id = v_resolved_id AND new_status_id = v_closed_id) THEN
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      VALUES (v_support_id, v_reporter_role_id, v_resolved_id, v_closed_id);
    END IF;
  END IF;

  -- Create workflow permissions for administrators
  DECLARE
    v_admin_role_id INTEGER;
    v_tracker_ids INTEGER[];
    v_status_ids INTEGER[];
  BEGIN
    -- Get admin role ID
    SELECT id INTO v_admin_role_id FROM roles WHERE builtin = 1; -- Admin role has builtin = 1
    
    IF v_admin_role_id IS NOT NULL THEN
      -- Get all tracker IDs
      SELECT array_agg(id) INTO v_tracker_ids FROM trackers;
      
      -- Get all status IDs
      SELECT array_agg(id) INTO v_status_ids FROM issue_statuses;
      
      -- Create transitions for admin from any status to any status for all trackers
      IF v_tracker_ids IS NOT NULL AND v_status_ids IS NOT NULL THEN
        FOR v_tracker_id IN SELECT unnest(v_tracker_ids)
        LOOP
          FOR v_old_status_id IN SELECT unnest(v_status_ids)
          LOOP
            FOR v_new_status_id IN SELECT unnest(v_status_ids)
            LOOP
              -- Skip same status transitions
              IF v_old_status_id <> v_new_status_id THEN
                IF NOT EXISTS (SELECT 1 FROM workflows 
                  WHERE tracker_id = v_tracker_id 
                  AND role_id = v_admin_role_id 
                  AND old_status_id = v_old_status_id 
                  AND new_status_id = v_new_status_id) THEN
                  
                  INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
                  VALUES (v_tracker_id, v_admin_role_id, v_old_status_id, v_new_status_id);
                END IF;
              END IF;
            END LOOP;
          END LOOP;
        END LOOP;
      END IF;
    END IF;
  END;
END $$;