-- V4__Issue_Tracking.sql
-- Issue tracking tables for Redmine PostgreSQL database
-- This migration sets up the tables for issue tracking

-- Issues table
CREATE TABLE issues (
  id SERIAL PRIMARY KEY,
  tracker_id INTEGER NOT NULL,
  project_id INTEGER NOT NULL,
  subject VARCHAR(255) NOT NULL,
  description TEXT,
  due_date DATE,
  category_id INTEGER,
  status_id INTEGER NOT NULL,
  assigned_to_id INTEGER,
  priority_id INTEGER NOT NULL,
  fixed_version_id INTEGER,
  author_id INTEGER NOT NULL,
  lock_version INTEGER DEFAULT 0,
  created_on TIMESTAMP,
  updated_on TIMESTAMP,
  start_date DATE,
  done_ratio INTEGER DEFAULT 0,
  estimated_hours FLOAT,
  parent_id INTEGER,
  root_id INTEGER,
  lft INTEGER,
  rgt INTEGER,
  is_private BOOLEAN DEFAULT false,
  closed_on TIMESTAMP
);
CREATE INDEX index_issues_on_assigned_to_id ON issues (assigned_to_id);
CREATE INDEX index_issues_on_author_id ON issues (author_id);
CREATE INDEX index_issues_on_category_id ON issues (category_id);
CREATE INDEX index_issues_on_created_on ON issues (created_on);
CREATE INDEX index_issues_on_fixed_version_id ON issues (fixed_version_id);
CREATE INDEX index_issues_on_parent_id ON issues (parent_id);
CREATE INDEX index_issues_on_priority_id ON issues (priority_id);
CREATE INDEX index_issues_on_project_id ON issues (project_id);
CREATE INDEX index_issues_on_root_id_and_lft_and_rgt ON issues (root_id, lft, rgt);
CREATE INDEX index_issues_on_status_id ON issues (status_id);
CREATE INDEX index_issues_on_tracker_id ON issues (tracker_id);

-- Issue categories
CREATE TABLE issue_categories (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL,
  name VARCHAR(255) NOT NULL,
  assigned_to_id INTEGER
);
CREATE INDEX index_issue_categories_on_assigned_to_id ON issue_categories (assigned_to_id);
CREATE INDEX index_issue_categories_on_project_id ON issue_categories (project_id);

-- Issue relations
CREATE TABLE issue_relations (
  id SERIAL PRIMARY KEY,
  issue_from_id INTEGER NOT NULL,
  issue_to_id INTEGER NOT NULL,
  relation_type VARCHAR(255) NOT NULL,
  delay INTEGER
);
CREATE UNIQUE INDEX index_issue_relations_on_issue_from_id_and_issue_to_id ON issue_relations (issue_from_id, issue_to_id);
CREATE INDEX index_issue_relations_on_issue_from_id ON issue_relations (issue_from_id);
CREATE INDEX index_issue_relations_on_issue_to_id ON issue_relations (issue_to_id);

-- Time entries
CREATE TABLE time_entries (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL,
  issue_id INTEGER,
  hours FLOAT NOT NULL,
  comments VARCHAR(1024),
  activity_id INTEGER NOT NULL,
  spent_on DATE NOT NULL,
  tyear INTEGER NOT NULL,
  tmonth INTEGER NOT NULL,
  tweek INTEGER NOT NULL,
  created_on TIMESTAMP,
  updated_on TIMESTAMP
);
CREATE INDEX index_time_entries_on_activity_id ON time_entries (activity_id);
CREATE INDEX index_time_entries_on_created_on ON time_entries (created_on);
CREATE INDEX index_time_entries_on_issue_id ON time_entries (issue_id);
CREATE INDEX index_time_entries_on_project_id ON time_entries (project_id);
CREATE INDEX index_time_entries_on_user_id ON time_entries (user_id);
CREATE INDEX index_time_entries_on_user_id_and_spent_on ON time_entries (user_id, spent_on);

-- Versions
CREATE TABLE versions (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL,
  name VARCHAR(255) NOT NULL,
  description VARCHAR(255) DEFAULT '',
  effective_date DATE,
  created_on TIMESTAMP,
  updated_on TIMESTAMP,
  wiki_page_title VARCHAR(255),
  status VARCHAR(255) DEFAULT 'open',
  sharing VARCHAR(255) DEFAULT 'none'
);
CREATE INDEX index_versions_on_project_id ON versions (project_id);
CREATE INDEX index_versions_on_sharing ON versions (sharing);

-- Watchers
CREATE TABLE watchers (
  id SERIAL PRIMARY KEY,
  watchable_type VARCHAR(255) NOT NULL,
  watchable_id INTEGER NOT NULL,
  user_id INTEGER NOT NULL
);
CREATE INDEX index_watchers_on_user_id ON watchers (user_id);
CREATE INDEX index_watchers_on_watchable_id_and_watchable_type ON watchers (watchable_id, watchable_type);

-- Journals (for issue history)
CREATE TABLE journals (
  id SERIAL PRIMARY KEY,
  journalized_id INTEGER NOT NULL,
  journalized_type VARCHAR(255) NOT NULL,
  user_id INTEGER NOT NULL,
  notes TEXT,
  created_on TIMESTAMP NOT NULL,
  private_notes BOOLEAN DEFAULT false
);
CREATE INDEX journals_journalized_id ON journals (journalized_id, journalized_type);
CREATE INDEX index_journals_on_created_on ON journals (created_on);
CREATE INDEX index_journals_on_journalized_id ON journals (journalized_id);
CREATE INDEX index_journals_on_journalized_type ON journals (journalized_type);
CREATE INDEX index_journals_on_user_id ON journals (user_id);

-- Journal details (changes)
CREATE TABLE journal_details (
  id SERIAL PRIMARY KEY,
  journal_id INTEGER NOT NULL,
  property VARCHAR(255) NOT NULL,
  prop_key VARCHAR(255) NOT NULL,
  old_value TEXT,
  value TEXT
);
CREATE INDEX journal_details_journal_id ON journal_details (journal_id);

-- Custom values (for custom fields)
CREATE TABLE custom_values (
  id SERIAL PRIMARY KEY,
  customized_type VARCHAR(255) NOT NULL,
  customized_id INTEGER NOT NULL,
  custom_field_id INTEGER NOT NULL,
  value TEXT
);
CREATE INDEX custom_values_customized ON custom_values (customized_type, customized_id);
CREATE INDEX index_custom_values_on_custom_field_id ON custom_values (custom_field_id);

-- Custom fields trackers (join table)
CREATE TABLE custom_fields_trackers (
  custom_field_id INTEGER NOT NULL,
  tracker_id INTEGER NOT NULL
);
CREATE UNIQUE INDEX index_custom_fields_trackers_on_custom_field_id_and_tracker_id ON custom_fields_trackers (custom_field_id, tracker_id);

-- Custom fields projects (join table)
CREATE TABLE custom_fields_projects (
  custom_field_id INTEGER NOT NULL,
  project_id INTEGER NOT NULL
);
CREATE UNIQUE INDEX index_custom_fields_projects_on_custom_field_id_and_project_id ON custom_fields_projects (custom_field_id, project_id);

-- Queries (saved filters)
CREATE TABLE queries (
  id SERIAL PRIMARY KEY,
  project_id INTEGER,
  name VARCHAR(255) NOT NULL,
  filters TEXT,
  user_id INTEGER NOT NULL,
  column_names TEXT,
  sort_criteria TEXT,
  group_by VARCHAR(255),
  type VARCHAR(255),
  visibility INTEGER DEFAULT 0,
  options TEXT,
  is_public BOOLEAN DEFAULT false,
  is_hidden BOOLEAN DEFAULT false
);
CREATE INDEX index_queries_on_project_id ON queries (project_id);
CREATE INDEX index_queries_on_user_id ON queries (user_id);

-- Default issue tracking settings
INSERT INTO settings (name, value, updated_on)
VALUES 
('issue_done_ratio', 'issue_field', NOW()),
('non_working_week_days', '---
- "6"
- "7"
', NOW()),
('issue_list_default_columns', '---
- tracker
- status
- priority
- subject
- assigned_to
- updated_on
', NOW()),
('default_issue_query', NULL, NOW()),
('cross_project_issue_relations', '1', NOW()),
('allow_issue_assignment_to_groups', '0', NOW()),
('show_status_changes_in_mail_subject', '0', NOW()),
('issue_group_assignment', '0', NOW());
