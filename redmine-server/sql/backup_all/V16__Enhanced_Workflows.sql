-- V16__Enhanced_Workflows.sql
-- Enhanced workflows for Redmine MCP
-- Part of the ModelContextProtocol (MCP) Implementation

-- Create additional statuses
DO $$
BEGIN
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

-- Define additional workflow transitions
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

  -- Developer role enhanced workflows
  IF v_dev_role_id IS NOT NULL THEN
    -- Blocked transitions
    IF v_bug_id IS NOT NULL THEN
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
    END IF;

    -- Ready for QA transitions for all trackers
    FOR v_tracker_id IN 
      SELECT id FROM trackers WHERE id IN (v_bug_id, v_feature_id, v_task_id, v_story_id)
    LOOP
      -- In Progress -> Ready for QA
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_tracker_id AND role_id = v_dev_role_id AND old_status_id = v_in_progress_id AND new_status_id = v_ready_for_qa_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_tracker_id, v_dev_role_id, v_in_progress_id, v_ready_for_qa_id);
      END IF;
      
      -- Ready for QA -> In Progress (if QA finds issues)
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_tracker_id AND role_id = v_dev_role_id AND old_status_id = v_ready_for_qa_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_tracker_id, v_dev_role_id, v_ready_for_qa_id, v_in_progress_id);
      END IF;
    END LOOP;
  END IF;

  -- QA Role (Reporter) enhanced workflows
  IF v_reporter_role_id IS NOT NULL THEN
    -- QA verification transitions for all trackers
    FOR v_tracker_id IN 
      SELECT id FROM trackers WHERE id IN (v_bug_id, v_feature_id, v_task_id, v_story_id)
    LOOP
      -- Ready for QA -> Verified
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_tracker_id AND role_id = v_reporter_role_id AND old_status_id = v_ready_for_qa_id AND new_status_id = v_verified_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_tracker_id, v_reporter_role_id, v_ready_for_qa_id, v_verified_id);
      END IF;
      
      -- Ready for QA -> In Progress (rejection)
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_tracker_id AND role_id = v_reporter_role_id AND old_status_id = v_ready_for_qa_id AND new_status_id = v_in_progress_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_tracker_id, v_reporter_role_id, v_ready_for_qa_id, v_in_progress_id);
      END IF;
    END LOOP;
  END IF;

  -- Manager role enhanced workflows
  IF v_manager_role_id IS NOT NULL THEN
    -- On Hold transitions for all trackers
    FOR v_tracker_id IN 
      SELECT id FROM trackers WHERE id IN (v_bug_id, v_feature_id, v_task_id, v_story_id, v_epic_id)
    LOOP
      -- Any status -> On Hold
      FOR v_status_id IN 
        SELECT id FROM issue_statuses WHERE id IN (v_new_id, v_in_progress_id, v_feedback_id, v_blocked_id)
      LOOP
        IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_tracker_id AND role_id = v_manager_role_id AND old_status_id = v_status_id AND new_status_id = v_on_hold_id) THEN
          INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
          VALUES (v_tracker_id, v_manager_role_id, v_status_id, v_on_hold_id);
        END IF;
      END LOOP;
      
      -- On Hold -> New (reactivation)
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_tracker_id AND role_id = v_manager_role_id AND old_status_id = v_on_hold_id AND new_status_id = v_new_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_tracker_id, v_manager_role_id, v_on_hold_id, v_new_id);
      END IF;
      
      -- Verified -> Closed
      IF NOT EXISTS (SELECT 1 FROM workflows WHERE tracker_id = v_tracker_id AND role_id = v_manager_role_id AND old_status_id = v_verified_id AND new_status_id = v_closed_id) THEN
        INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
        VALUES (v_tracker_id, v_manager_role_id, v_verified_id, v_closed_id);
      END IF;
    END LOOP;
  END IF;
END $$;

-- Create workflow permissions for administrators
DO $$
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
END $$;