-- add_custom_tracker.sql
-- Script to add a new tracker to Redmine database
-- Part of the ModelContextProtocol (MCP) Implementation

-- Create a new tracker for MCP Documentation
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM trackers WHERE name = 'MCP Documentation') THEN
    INSERT INTO trackers (name, position, is_in_roadmap, fields_bits, description)
    VALUES ('MCP Documentation', 
            (SELECT COALESCE(MAX(position), 0) + 1 FROM trackers),
            TRUE,
            0,
            'Documentation for ModelContextProtocol (MCP) implementation and features');
  END IF;
END $$;

-- Associate the new tracker with the MCP project
DO $$
DECLARE
  v_project_id INTEGER;
  v_tracker_id INTEGER;
BEGIN
  -- Get project ID
  SELECT id INTO v_project_id FROM projects WHERE identifier = 'mcp-project';
  
  -- Get tracker ID
  SELECT id INTO v_tracker_id FROM trackers WHERE name = 'MCP Documentation';

  -- Associate tracker with the project if both exist
  IF v_project_id IS NOT NULL AND v_tracker_id IS NOT NULL THEN
    -- Check if association already exists
    IF NOT EXISTS (SELECT 1 FROM projects_trackers 
                  WHERE project_id = v_project_id AND tracker_id = v_tracker_id) THEN
      -- Create association
      INSERT INTO projects_trackers (project_id, tracker_id)
      VALUES (v_project_id, v_tracker_id);
    END IF;
  END IF;
END $$;

-- Set up workflow for the new tracker
DO $$
DECLARE
  v_new_id INTEGER;
  v_in_progress_id INTEGER;
  v_feedback_id INTEGER;
  v_resolved_id INTEGER;
  v_closed_id INTEGER;
  v_doc_tracker_id INTEGER;
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
  
  -- Get tracker ID
  SELECT id INTO v_doc_tracker_id FROM trackers WHERE name = 'MCP Documentation';

  -- Get role IDs
  SELECT id INTO v_dev_role_id FROM roles WHERE name = 'Developer';
  SELECT id INTO v_manager_role_id FROM roles WHERE name = 'Manager';
  SELECT id INTO v_reporter_role_id FROM roles WHERE name = 'Reporter';

  -- Setup workflow for Developer role
  IF v_dev_role_id IS NOT NULL AND v_doc_tracker_id IS NOT NULL THEN
    -- New -> In Progress transition
    IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_doc_tracker_id AND role_id = v_dev_role_id 
                   AND old_status_id = v_new_id AND new_status_id = v_in_progress_id) THEN
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      VALUES (v_doc_tracker_id, v_dev_role_id, v_new_id, v_in_progress_id);
    END IF;
    
    -- In Progress -> Resolved transition
    IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_doc_tracker_id AND role_id = v_dev_role_id 
                   AND old_status_id = v_in_progress_id AND new_status_id = v_resolved_id) THEN
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      VALUES (v_doc_tracker_id, v_dev_role_id, v_in_progress_id, v_resolved_id);
    END IF;
    
    -- In Progress -> Feedback transition
    IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_doc_tracker_id AND role_id = v_dev_role_id 
                   AND old_status_id = v_in_progress_id AND new_status_id = v_feedback_id) THEN
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      VALUES (v_doc_tracker_id, v_dev_role_id, v_in_progress_id, v_feedback_id);
    END IF;
    
    -- Feedback -> In Progress transition
    IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_doc_tracker_id AND role_id = v_dev_role_id 
                   AND old_status_id = v_feedback_id AND new_status_id = v_in_progress_id) THEN
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      VALUES (v_doc_tracker_id, v_dev_role_id, v_feedback_id, v_in_progress_id);
    END IF;
  END IF;

  -- Setup workflow for Manager role
  IF v_manager_role_id IS NOT NULL AND v_doc_tracker_id IS NOT NULL THEN
    -- New -> In Progress transition
    IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_doc_tracker_id AND role_id = v_manager_role_id 
                   AND old_status_id = v_new_id AND new_status_id = v_in_progress_id) THEN
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      VALUES (v_doc_tracker_id, v_manager_role_id, v_new_id, v_in_progress_id);
    END IF;
    
    -- Resolved -> Closed transition
    IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_doc_tracker_id AND role_id = v_manager_role_id 
                   AND old_status_id = v_resolved_id AND new_status_id = v_closed_id) THEN
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      VALUES (v_doc_tracker_id, v_manager_role_id, v_resolved_id, v_closed_id);
    END IF;
  END IF;

  -- Setup workflow for Reporter role (more limited)
  IF v_reporter_role_id IS NOT NULL AND v_doc_tracker_id IS NOT NULL THEN
    -- New -> Feedback transition
    IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_doc_tracker_id AND role_id = v_reporter_role_id 
                   AND old_status_id = v_new_id AND new_status_id = v_feedback_id) THEN
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      VALUES (v_doc_tracker_id, v_reporter_role_id, v_new_id, v_feedback_id);
    END IF;
    
    -- Resolved -> Feedback transition
    IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_doc_tracker_id AND role_id = v_reporter_role_id 
                   AND old_status_id = v_resolved_id AND new_status_id = v_feedback_id) THEN
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      VALUES (v_doc_tracker_id, v_reporter_role_id, v_resolved_id, v_feedback_id);
    END IF;
  END IF;
END $$;

-- Add another tracker for MCP Testing
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM trackers WHERE name = 'MCP Test Case') THEN
    INSERT INTO trackers (name, position, is_in_roadmap, fields_bits, description)
    VALUES ('MCP Test Case', 
            (SELECT COALESCE(MAX(position), 0) + 1 FROM trackers),
            TRUE,
            0,
            'Test cases for ModelContextProtocol (MCP) implementation and features');
  END IF;
END $$;

-- Associate the MCP Test Case tracker with the project
DO $$
DECLARE
  v_project_id INTEGER;
  v_tracker_id INTEGER;
BEGIN
  -- Get project ID
  SELECT id INTO v_project_id FROM projects WHERE identifier = 'mcp-project';
  
  -- Get tracker ID
  SELECT id INTO v_tracker_id FROM trackers WHERE name = 'MCP Test Case';

  -- Associate with the project if both exist
  IF v_project_id IS NOT NULL AND v_tracker_id IS NOT NULL THEN
    -- Check if association already exists
    IF NOT EXISTS (SELECT 1 FROM projects_trackers 
                  WHERE project_id = v_project_id AND tracker_id = v_tracker_id) THEN
      -- Create association
      INSERT INTO projects_trackers (project_id, tracker_id)
      VALUES (v_project_id, v_tracker_id);
    END IF;
  END IF;
END $$;

-- Set up basic workflow for the Test Case tracker
DO $$
DECLARE
  v_new_id INTEGER;
  v_in_progress_id INTEGER;
  v_resolved_id INTEGER;
  v_closed_id INTEGER;
  v_test_tracker_id INTEGER;
  v_dev_role_id INTEGER;
  v_manager_role_id INTEGER;
BEGIN
  -- Get status IDs
  SELECT id INTO v_new_id FROM issue_statuses WHERE name = 'New';
  SELECT id INTO v_in_progress_id FROM issue_statuses WHERE name = 'In Progress';
  SELECT id INTO v_resolved_id FROM issue_statuses WHERE name = 'Resolved';
  SELECT id INTO v_closed_id FROM issue_statuses WHERE name = 'Closed';
  
  -- Get tracker ID and role IDs
  SELECT id INTO v_test_tracker_id FROM trackers WHERE name = 'MCP Test Case';
  SELECT id INTO v_dev_role_id FROM roles WHERE name = 'Developer';
  SELECT id INTO v_manager_role_id FROM roles WHERE name = 'Manager';

  -- Setup basic workflow for Developer role
  IF v_dev_role_id IS NOT NULL AND v_test_tracker_id IS NOT NULL THEN
    -- New -> In Progress transition
    IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_test_tracker_id AND role_id = v_dev_role_id 
                   AND old_status_id = v_new_id AND new_status_id = v_in_progress_id) THEN
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      VALUES (v_test_tracker_id, v_dev_role_id, v_new_id, v_in_progress_id);
    END IF;
    
    -- In Progress -> Resolved transition
    IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_test_tracker_id AND role_id = v_dev_role_id 
                   AND old_status_id = v_in_progress_id AND new_status_id = v_resolved_id) THEN
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      VALUES (v_test_tracker_id, v_dev_role_id, v_in_progress_id, v_resolved_id);
    END IF;
  END IF;

  -- Setup basic workflow for Manager role
  IF v_manager_role_id IS NOT NULL AND v_test_tracker_id IS NOT NULL THEN
    -- New -> In Progress transition
    IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_test_tracker_id AND role_id = v_manager_role_id 
                   AND old_status_id = v_new_id AND new_status_id = v_in_progress_id) THEN
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      VALUES (v_test_tracker_id, v_manager_role_id, v_new_id, v_in_progress_id);
    END IF;
    
    -- Resolved -> Closed transition
    IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_test_tracker_id AND role_id = v_manager_role_id 
                   AND old_status_id = v_resolved_id AND new_status_id = v_closed_id) THEN
      INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
      VALUES (v_test_tracker_id, v_manager_role_id, v_resolved_id, v_closed_id);
    END IF;
  END IF;
END $$;