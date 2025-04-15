-- V1__Base_Schema.sql
-- Base schema for Redmine PostgreSQL database
-- This migration creates the core tables required for Redmine

-- Enable UUID extension for secure ID generation
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- User-related tables
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  login VARCHAR(255) NOT NULL,
  hashed_password VARCHAR(255) NOT NULL,
  firstname VARCHAR(255) NOT NULL,
  lastname VARCHAR(255) NOT NULL,
  admin BOOLEAN DEFAULT false,
  status INTEGER DEFAULT 1,
  last_login_on TIMESTAMP,
  language VARCHAR(5) DEFAULT '',
  auth_source_id INTEGER,
  created_on TIMESTAMP,
  updated_on TIMESTAMP,
  type VARCHAR(255),
  identity_url VARCHAR(255),
  mail_notification VARCHAR(255) DEFAULT '',
  salt VARCHAR(64),
  must_change_passwd BOOLEAN DEFAULT false,
  passwd_changed_on TIMESTAMP,
  twofa_scheme VARCHAR(255),
  twofa_totp_key VARCHAR(255),
  twofa_totp_last_used_at INTEGER
);
CREATE INDEX index_users_on_auth_source_id ON users (auth_source_id);
CREATE INDEX index_users_on_id_and_type ON users (id, type);
CREATE INDEX index_users_on_status ON users (status);
CREATE INDEX index_users_on_twofa_scheme ON users (twofa_scheme);
CREATE INDEX index_users_on_type ON users (type);
CREATE UNIQUE INDEX index_users_on_login ON users (login);

-- Email addresses table
CREATE TABLE email_addresses (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  address VARCHAR(255) NOT NULL,
  is_default BOOLEAN DEFAULT false,
  notify BOOLEAN DEFAULT true,
  created_on TIMESTAMP,
  updated_on TIMESTAMP
);
CREATE INDEX index_email_addresses_on_user_id ON email_addresses (user_id);
CREATE INDEX index_email_addresses_on_user_id_and_is_default ON email_addresses (user_id, is_default);

-- Token table for API keys, feeds, etc.
CREATE TABLE tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER DEFAULT NULL, 
  action VARCHAR(30) NOT NULL,
  value VARCHAR(128) NOT NULL,
  created_on TIMESTAMP,
  updated_on TIMESTAMP
);
CREATE UNIQUE INDEX tokens_value ON tokens (value);
CREATE INDEX index_tokens_on_user_id ON tokens (user_id);

-- Project table
CREATE TABLE projects (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT,
  homepage VARCHAR(255) DEFAULT '',
  is_public BOOLEAN DEFAULT true,
  parent_id INTEGER,
  created_on TIMESTAMP,
  updated_on TIMESTAMP,
  identifier VARCHAR(255),
  status INTEGER DEFAULT 1,
  lft INTEGER,
  rgt INTEGER,
  inherit_members BOOLEAN DEFAULT false,
  default_version_id INTEGER,
  default_assigned_to_id INTEGER
);
CREATE INDEX index_projects_on_lft ON projects (lft);
CREATE INDEX index_projects_on_rgt ON projects (rgt);
CREATE INDEX index_projects_on_parent_id ON projects (parent_id);
CREATE UNIQUE INDEX index_projects_on_identifier ON projects (identifier);

-- Modules table (join table for projects and enabled modules)
CREATE TABLE enabled_modules (
  id SERIAL PRIMARY KEY,
  project_id INTEGER NOT NULL,
  name VARCHAR(255) NOT NULL
);
CREATE INDEX enabled_modules_project_id ON enabled_modules (project_id);

-- Members table (users assigned to projects)
CREATE TABLE members (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL,
  project_id INTEGER NOT NULL,
  created_on TIMESTAMP,
  mail_notification BOOLEAN DEFAULT false
);
CREATE INDEX index_members_on_project_id ON members (project_id);
CREATE INDEX index_members_on_user_id ON members (user_id);
CREATE UNIQUE INDEX index_members_on_user_id_and_project_id ON members (user_id, project_id);

-- Roles
CREATE TABLE roles (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  position INTEGER DEFAULT 1,
  assignable BOOLEAN DEFAULT true,
  builtin INTEGER DEFAULT 0,
  permissions TEXT,
  issues_visibility VARCHAR(30) DEFAULT 'default',
  users_visibility VARCHAR(30) DEFAULT 'all',
  time_entries_visibility VARCHAR(30) DEFAULT 'all',
  all_roles_managed BOOLEAN DEFAULT true,
  settings TEXT
);
CREATE INDEX index_roles_on_builtin ON roles (builtin);
CREATE INDEX index_roles_on_position ON roles (position);

-- Member roles
CREATE TABLE member_roles (
  id SERIAL PRIMARY KEY,
  member_id INTEGER NOT NULL,
  role_id INTEGER NOT NULL,
  inherited_from INTEGER
);
CREATE INDEX index_member_roles_on_member_id ON member_roles (member_id);
CREATE INDEX index_member_roles_on_role_id ON member_roles (role_id);
CREATE INDEX index_member_roles_on_inherited_from ON member_roles (inherited_from);

-- Trackers
CREATE TABLE trackers (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  description TEXT DEFAULT '',
  is_in_roadmap BOOLEAN DEFAULT true,
  position INTEGER,
  default_status_id INTEGER,
  fields_bits INTEGER DEFAULT 0
);
CREATE INDEX index_trackers_on_position ON trackers (position);

-- Projects Trackers (join table)
CREATE TABLE projects_trackers (
  project_id INTEGER NOT NULL,
  tracker_id INTEGER NOT NULL
);
CREATE UNIQUE INDEX projects_trackers_unique_idx ON projects_trackers (project_id, tracker_id);

-- Enumerations
CREATE TABLE enumerations (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  position INTEGER,
  is_default BOOLEAN DEFAULT false,
  type VARCHAR(255),
  active BOOLEAN DEFAULT true,
  project_id INTEGER,
  parent_id INTEGER,
  position_name VARCHAR(255)
);
CREATE INDEX index_enumerations_on_id_and_type ON enumerations (id, type);
CREATE INDEX index_enumerations_on_position ON enumerations (position);
CREATE INDEX index_enumerations_on_project_id ON enumerations (project_id);

-- Custom fields
CREATE TABLE custom_fields (
  id SERIAL PRIMARY KEY,
  type VARCHAR(255) NOT NULL,
  name VARCHAR(255) NOT NULL,
  field_format VARCHAR(255) NOT NULL,
  possible_values TEXT,
  regexp VARCHAR(255),
  min_length INTEGER,
  max_length INTEGER,
  is_required BOOLEAN DEFAULT false,
  is_for_all BOOLEAN DEFAULT false,
  is_filter BOOLEAN DEFAULT false,
  position INTEGER,
  searchable BOOLEAN DEFAULT false,
  default_value TEXT,
  editable BOOLEAN DEFAULT true,
  visible BOOLEAN DEFAULT true,
  multiple BOOLEAN DEFAULT false,
  format_store TEXT,
  description TEXT
);
CREATE INDEX index_custom_fields_on_id_and_type ON custom_fields (id, type);

-- Issue statuses
CREATE TABLE issue_statuses (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  is_closed BOOLEAN DEFAULT false,
  position INTEGER,
  default_done_ratio INTEGER
);
CREATE INDEX index_issue_statuses_on_position ON issue_statuses (position);

-- Workflow table
CREATE TABLE workflows (
  id SERIAL PRIMARY KEY,
  tracker_id INTEGER NOT NULL,
  old_status_id INTEGER NOT NULL,
  new_status_id INTEGER NOT NULL,
  role_id INTEGER NOT NULL,
  assignee BOOLEAN DEFAULT false,
  author BOOLEAN DEFAULT false,
  type VARCHAR(255),
  field_name VARCHAR(255),
  rule VARCHAR(255)
);
CREATE INDEX workflows_old_status_id_tracker_id ON workflows (old_status_id, tracker_id);
CREATE INDEX workflows_role_id ON workflows (role_id);
CREATE INDEX index_workflows_on_tracker_id ON workflows (tracker_id);
CREATE INDEX index_workflows_on_new_status_id ON workflows (new_status_id);

-- Settings table
CREATE TABLE settings (
  id SERIAL PRIMARY KEY,
  name VARCHAR(255) NOT NULL,
  value TEXT,
  updated_on TIMESTAMP
);
CREATE UNIQUE INDEX index_settings_on_name ON settings (name);
