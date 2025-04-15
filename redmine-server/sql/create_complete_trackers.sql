-- create_complete_trackers.sql
-- Script to create fully configured trackers for Redmine MCP
-- Part of the ModelContextProtocol (MCP) Implementation

-- Get the 'New' status ID for reference
DO $$
DECLARE
  v_new_status_id INTEGER;
  v_project_id INTEGER;
  v_doc_tracker_id INTEGER;
  v_test_tracker_id INTEGER;
  v_manager_role_id INTEGER;
  v_dev_role_id INTEGER;
  v_reporter_role_id INTEGER;
  v_in_progress_id INTEGER;
  v_feedback