-- V13__Create_Statuses_Workflows.sql
-- Create issue statuses and workflows for Redmine MCP
-- Part of the ModelContextProtocol (MCP) Implementation

-- Create issue statuses
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
END $$;

-- Define workflow transitions for each role and tracker
DO $$
DECLARE
  v_new_id INTEGER;
  v_in_progress_id INTEGER;
  v_feedback_id INTEGER;
  v_resolved_id INTEGER;
  v_closed_id INTEGER;
  v_rejected_id INTEGER;
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
    END IF;
  END IF;

  -- For Feature tracker (similar to Bug but with subtle differences)
  IF v_feature_id IS NOT NULL THEN
    -- Developer role feature workflow
    IF v_dev_role_id IS NOT NULL THEN
      -- New -> In Progress transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_feature_id AND role_id = v_dev_role_id AND old_status_id = v_new_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_feature_id, v_dev_role_id, v_new_id, v_in_progress_id);
      END IF;
      
      -- In Progress -> Resolved transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_feature_id AND role_id = v_dev_role_id AND old_status_id = v_in_progress_id AND new_status_id = v_resolved_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_feature_id, v_dev_role_id, v_in_progress_id, v_resolved_id);
      END IF;
      
      -- In Progress -> Feedback transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_feature_id AND role_id = v_dev_role_id AND old_status_id = v_in_progress_id AND new_status_id = v_feedback_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_feature_id, v_dev_role_id, v_in_progress_id, v_feedback_id);
      END IF;
      
      -- Feedback -> In Progress transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_feature_id AND role_id = v_dev_role_id AND old_status_id = v_feedback_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_feature_id, v_dev_role_id, v_feedback_id, v_in_progress_id);
      END IF;
    END IF;

    -- Manager role feature workflow
    IF v_manager_role_id IS NOT NULL THEN
      -- New -> In Progress transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_feature_id AND role_id = v_manager_role_id AND old_status_id = v_new_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_feature_id, v_manager_role_id, v_new_id, v_in_progress_id);
      END IF;
      
      -- New -> Rejected transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_feature_id AND role_id = v_manager_role_id AND old_status_id = v_new_id AND new_status_id = v_rejected_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_feature_id, v_manager_role_id, v_new_id, v_rejected_id);
      END IF;
      
      -- Resolved -> Closed transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_feature_id AND role_id = v_manager_role_id AND old_status_id = v_resolved_id AND new_status_id = v_closed_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_feature_id, v_manager_role_id, v_resolved_id, v_closed_id);
      END IF;
      
      -- Resolved -> Feedback transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_feature_id AND role_id = v_manager_role_id AND old_status_id = v_resolved_id AND new_status_id = v_feedback_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_feature_id, v_manager_role_id, v_resolved_id, v_feedback_id);
      END IF;
    END IF;
  END IF;

  -- For Support tracker (more relaxed workflow)
  IF v_support_id IS NOT NULL THEN
    -- Developer role support workflow
    IF v_dev_role_id IS NOT NULL THEN
      -- New -> In Progress transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_support_id AND role_id = v_dev_role_id AND old_status_id = v_new_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_support_id, v_dev_role_id, v_new_id, v_in_progress_id);
      END IF;
      
      -- New -> Feedback transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_support_id AND role_id = v_dev_role_id AND old_status_id = v_new_id AND new_status_id = v_feedback_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_support_id, v_dev_role_id, v_new_id, v_feedback_id);
      END IF;
      
      -- In Progress -> Resolved transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_support_id AND role_id = v_dev_role_id AND old_status_id = v_in_progress_id AND new_status_id = v_resolved_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_support_id, v_dev_role_id, v_in_progress_id, v_resolved_id);
      END IF;
      
      -- Feedback -> In Progress transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_support_id AND role_id = v_dev_role_id AND old_status_id = v_feedback_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_support_id, v_dev_role_id, v_feedback_id, v_in_progress_id);
      END IF;
    END IF;

    -- Manager role support workflow (same as developer)
    IF v_manager_role_id IS NOT NULL THEN
      -- New -> In Progress transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_support_id AND role_id = v_manager_role_id AND old_status_id = v_new_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_support_id, v_manager_role_id, v_new_id, v_in_progress_id);
      END IF;
      
      -- New -> Feedback transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_support_id AND role_id = v_manager_role_id AND old_status_id = v_new_id AND new_status_id = v_feedback_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_support_id, v_manager_role_id, v_new_id, v_feedback_id);
      END IF;
      
      -- In Progress -> Resolved transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_support_id AND role_id = v_manager_role_id AND old_status_id = v_in_progress_id AND new_status_id = v_resolved_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_support_id, v_manager_role_id, v_in_progress_id, v_resolved_id);
      END IF;
      
      -- Feedback -> In Progress transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_support_id AND role_id = v_manager_role_id AND old_status_id = v_feedback_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_support_id, v_manager_role_id, v_feedback_id, v_in_progress_id);
      END IF;
    END IF;

    -- Reporter role support workflow
    IF v_reporter_role_id IS NOT NULL THEN
      -- New -> Feedback transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_support_id AND role_id = v_reporter_role_id AND old_status_id = v_new_id AND new_status_id = v_feedback_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_support_id, v_reporter_role_id, v_new_id, v_feedback_id);
      END IF;
      
      -- Resolved -> Closed transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_support_id AND role_id = v_reporter_role_id AND old_status_id = v_resolved_id AND new_status_id = v_closed_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_support_id, v_reporter_role_id, v_resolved_id, v_closed_id);
      END IF;
    END IF;
  END IF;

  -- For Task tracker
  IF v_task_id IS NOT NULL THEN
    -- Define similar workflows for Task tracker (similar to Bug workflow)
    -- Developer role task workflow
    IF v_dev_role_id IS NOT NULL THEN
      -- New -> In Progress transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_task_id AND role_id = v_dev_role_id AND old_status_id = v_new_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_task_id, v_dev_role_id, v_new_id, v_in_progress_id);
      END IF;
      
      -- In Progress -> Resolved transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_task_id AND role_id = v_dev_role_id AND old_status_id = v_in_progress_id AND new_status_id = v_resolved_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_task_id, v_dev_role_id, v_in_progress_id, v_resolved_id);
      END IF;
    END IF;

    -- Manager role task workflow
    IF v_manager_role_id IS NOT NULL THEN
      -- New -> In Progress transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_task_id AND role_id = v_manager_role_id AND old_status_id = v_new_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_task_id, v_manager_role_id, v_new_id, v_in_progress_id);
      END IF;
      
      -- Resolved -> Closed transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_task_id AND role_id = v_manager_role_id AND old_status_id = v_resolved_id AND new_status_id = v_closed_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_task_id, v_manager_role_id, v_resolved_id, v_closed_id);
      END IF;
    END IF;
  END IF;

  -- For Epic tracker
  IF v_epic_id IS NOT NULL THEN
    -- Define workflows for Epic tracker (mainly manager controlled)
    -- Manager role epic workflow
    IF v_manager_role_id IS NOT NULL THEN
      -- New -> In Progress transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_epic_id AND role_id = v_manager_role_id AND old_status_id = v_new_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_epic_id, v_manager_role_id, v_new_id, v_in_progress_id);
      END IF;
      
      -- In Progress -> Resolved transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_epic_id AND role_id = v_manager_role_id AND old_status_id = v_in_progress_id AND new_status_id = v_resolved_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_epic_id, v_manager_role_id, v_in_progress_id, v_resolved_id);
      END IF;
      
      -- Resolved -> Closed transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_epic_id AND role_id = v_manager_role_id AND old_status_id = v_resolved_id AND new_status_id = v_closed_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_epic_id, v_manager_role_id, v_resolved_id, v_closed_id);
      END IF;
    END IF;
  END IF;

  -- For Story tracker
  IF v_story_id IS NOT NULL THEN
    -- Define workflows for Story tracker (similar to Task)
    -- Developer role story workflow
    IF v_dev_role_id IS NOT NULL THEN
      -- New -> In Progress transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_story_id AND role_id = v_dev_role_id AND old_status_id = v_new_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_story_id, v_dev_role_id, v_new_id, v_in_progress_id);
      END IF;
      
      -- In Progress -> Resolved transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_story_id AND role_id = v_dev_role_id AND old_status_id = v_in_progress_id AND new_status_id = v_resolved_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_story_id, v_dev_role_id, v_in_progress_id, v_resolved_id);
      END IF;
    END IF;

    -- Manager role story workflow
    IF v_manager_role_id IS NOT NULL THEN
      -- New -> In Progress transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_story_id AND role_id = v_manager_role_id AND old_status_id = v_new_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_story_id, v_manager_role_id, v_new_id, v_in_progress_id);
      END IF;
      
      -- Resolved -> Closed transition
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_story_id AND role_id = v_manager_role_id AND old_status_id = v_resolved_id AND new_status_id = v_closed_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_story_id, v_manager_role_id, v_resolved_id, v_closed_id);
      END IF;
    END IF;
  END IF;
END $$;
