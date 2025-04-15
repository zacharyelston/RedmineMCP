-- V2__User_Management.sql
-- User management for Redmine PostgreSQL database
-- This migration handles users, roles, and permissions

-- Create default roles
INSERT INTO roles (name, position, builtin, permissions, issues_visibility, users_visibility, time_entries_visibility)
VALUES 
('Manager', 1, 0, 
'---
- :add_project
- :edit_project
- :close_project
- :delete_project
- :manage_members
- :manage_versions
- :add_subprojects
- :manage_categories
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
- :delete_issues
- :manage_public_queries
- :save_queries
- :view_gantt
- :view_calendar
- :log_time
- :view_time_entries
- :edit_time_entries
- :edit_own_time_entries
- :manage_project_activities
- :manage_news
- :comment_news
- :add_documents
- :edit_documents
- :delete_documents
- :view_wiki_pages
- :export_wiki_pages
- :view_wiki_edits
- :edit_wiki_pages
- :delete_wiki_pages
- :rename_wiki_pages
- :delete_wiki_pages_attachments
- :manage_files
- :browse_repository
- :manage_repository
- :view_changesets
- :manage_boards
- :add_messages
- :edit_messages
- :edit_own_messages
- :delete_messages
- :delete_own_messages
- :manage_watchers
', 'all', 'all', 'all'),

('Developer', 2, 0, 
'---
- :view_issues
- :add_issues
- :edit_issues
- :manage_issue_relations
- :manage_subtasks
- :add_issue_notes
- :view_private_notes
- :save_queries
- :view_gantt
- :view_calendar
- :log_time
- :view_time_entries
- :manage_news
- :comment_news
- :view_documents
- :view_wiki_pages
- :view_wiki_edits
- :edit_wiki_pages
- :browse_repository
- :view_changesets
- :add_messages
- :edit_own_messages
', 'default', 'all', 'all'),

('Reporter', 3, 0, 
'---
- :view_issues
- :add_issues
- :add_issue_notes
- :save_queries
- :view_gantt
- :view_calendar
- :view_time_entries
- :comment_news
- :view_documents
- :view_wiki_pages
- :view_wiki_edits
- :add_messages
- :edit_own_messages
', 'default', 'all', 'all'),

('Non member', 4, 1, 
'---
- :view_issues
- :add_issues
- :add_issue_notes
- :view_gantt
- :view_calendar
- :view_time_entries
- :view_documents
- :view_wiki_pages
- :view_wiki_edits
- :browse_repository
- :view_changesets
', 'default', 'all', 'all'),

('Anonymous', 5, 2, 
'---
- :view_issues
- :view_gantt
- :view_calendar
- :view_time_entries
- :view_documents
- :view_wiki_pages
- :view_wiki_edits
- :browse_repository
- :view_changesets
', 'default', 'all', 'all');

-- Create admin user
INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, language, created_on, updated_on, type)
VALUES ('admin', '$2a$10$ILJWa4Uy2X2G5Lb2TnW1IOVQFgwOOFWRbvwZZQQvkD7JNGmGQtGqi', 'Admin', 'User', TRUE, 1, 'en', NOW(), NOW(), 'User');

-- Create admin email
INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
VALUES (1, 'admin@example.com', TRUE, TRUE, NOW(), NOW());

-- Create API key for admin
INSERT INTO tokens (user_id, action, value, created_on, updated_on)
VALUES (1, 'api', '7a4ed5c91b405d30fda60909dbc86c2651c38217', NOW(), NOW());

-- Create test user
INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, language, created_on, updated_on, type)
VALUES ('testuser', '$2a$10$YSg9NWcGXJVsLKKRZrLYIOpOPJvL8G/v0srJWOuoF35ErPKnFVlYy', 'Test', 'User', FALSE, 1, 'en', NOW(), NOW(), 'User');

-- Create test user email
INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
VALUES (2, 'test@example.com', TRUE, TRUE, NOW(), NOW());

-- Create API key for test user
INSERT INTO tokens (user_id, action, value, created_on, updated_on)
VALUES (2, 'api', '3e9b7b22b84a26e7e95b3d73b6e65f6c3fe6e3f0', NOW(), NOW());

-- Create developer user
INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, language, created_on, updated_on, type)
VALUES ('developer', '$2a$10$YJGSqBYghOz2h2J3EG42zuRdQUwPcWX13JYOQoTr1xL3AGUBDsGiO', 'Dev', 'User', FALSE, 1, 'en', NOW(), NOW(), 'User');

-- Create developer email
INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
VALUES (3, 'dev@example.com', TRUE, TRUE, NOW(), NOW());

-- Create API key for developer
INSERT INTO tokens (user_id, action, value, created_on, updated_on)
VALUES (3, 'api', 'f91c59b0d78f2a10d9b7ea3c631d9f2cbba94f8f', NOW(), NOW());

-- Create manager user
INSERT INTO users (login, hashed_password, firstname, lastname, admin, status, language, created_on, updated_on, type)
VALUES ('manager', '$2a$10$W9iBKnNIQG1MN7H.pCgOXuKQZP.zQOc91RG8vBKftUPtYcFGBvQTW', 'Project', 'Manager', FALSE, 1, 'en', NOW(), NOW(), 'User');

-- Create manager email
INSERT INTO email_addresses (user_id, address, is_default, notify, created_on, updated_on)
VALUES (4, 'manager@example.com', TRUE, TRUE, NOW(), NOW());

-- Create API key for manager
INSERT INTO tokens (user_id, action, value, created_on, updated_on)
VALUES (4, 'api', '5c98f85a9f2e34c3b217758e910e196c7a77bf5b', NOW(), NOW());

-- Default settings for user management
INSERT INTO settings (name, value, updated_on)
VALUES 
('login_required', '0', NOW()),
('autologin', '7', NOW()),
('self_registration', '1', NOW()),
('unsubscribe', '1', NOW()),
('password_min_length', '8', NOW()),
('password_max_age', '0', NOW()),
('lost_password', '1', NOW()),
('twofa', '0', NOW()),
('rest_api_enabled', '1', NOW());
