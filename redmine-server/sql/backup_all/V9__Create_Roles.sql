-- V9__Create_Roles.sql
-- Create roles for Redmine MCP
-- Part of the ModelContextProtocol (MCP) Implementation

-- Create the Developer role if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM roles WHERE name = 'Developer') THEN
    INSERT INTO roles (name, position, assignable, builtin, permissions, issues_visibility, users_visibility, time_entries_visibility, all_roles_managed, settings)
    VALUES ('Developer', 3, TRUE, 0, '---
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
- :manage_public_queries
- :save_queries
- :view_issue_watchers
- :add_issue_watchers
- :delete_issue_watchers
- :import_issues
- :manage_categories
- :view_time_entries
- :log_time
- :edit_time_entries
- :edit_own_time_entries
- :manage_project_activities
- :log_time_for_other_users
- :import_time_entries', 'all', 'all', 'all', TRUE, '--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess
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
END $$;

-- Create the Manager role if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM roles WHERE name = 'Manager') THEN
    INSERT INTO roles (name, position, assignable, builtin, permissions, issues_visibility, users_visibility, time_entries_visibility, all_roles_managed, settings)
    VALUES ('Manager', 4, TRUE, 0, '---
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
- :manage_public_queries
- :save_queries
- :view_issue_watchers
- :add_issue_watchers
- :delete_issue_watchers
- :import_issues
- :manage_categories
- :view_time_entries
- :log_time
- :edit_time_entries
- :edit_own_time_entries
- :manage_project_activities
- :log_time_for_other_users
- :import_time_entries
- :manage_news
- :comment_news
- :manage_documents
- :view_documents
- :manage_files
- :view_files
- :manage_wiki
- :rename_wiki_pages
- :delete_wiki_pages
- :view_wiki_pages
- :export_wiki_pages
- :view_wiki_edits
- :edit_wiki_pages
- :delete_wiki_pages_attachments
- :protect_wiki_pages
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
- :view_calendar
- :view_gantt', 'all', 'all', 'all', TRUE, '--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess
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
END $$;

-- Create the Reporter role if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM roles WHERE name = 'Reporter') THEN
    INSERT INTO roles (name, position, assignable, builtin, permissions, issues_visibility, users_visibility, time_entries_visibility, all_roles_managed, settings)
    VALUES ('Reporter', 5, TRUE, 0, '---
- :view_issues
- :add_issues
- :add_issue_notes
- :save_queries
- :view_gantt
- :view_calendar
- :log_time
- :view_time_entries
- :view_wiki_pages
- :view_wiki_edits', 'default', 'all', 'all', TRUE, '--- !ruby/hash:ActiveSupport::HashWithIndifferentAccess
permissions_all_trackers: !ruby/hash:ActiveSupport::HashWithIndifferentAccess
  view_issues: ''1''
  add_issues: ''1''
  add_issue_notes: ''1''
permissions_tracker_ids: !ruby/hash:ActiveSupport::HashWithIndifferentAccess
  view_issues: []
  add_issues: []
  add_issue_notes: []');
  END IF;
END $$;
