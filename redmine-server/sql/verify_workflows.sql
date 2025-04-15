-- verify_workflows.sql
-- Verify workflow configuration
-- For issue #103 - Workflow Challenge

-- First check if workflows exist for the Feature tracker
SELECT 
  COUNT(*) AS workflow_count
FROM 
  workflows w
JOIN 
  trackers t ON w.tracker_id = t.id
WHERE 
  t.name = 'Feature';

-- Check workflow configuration for issue #93
SELECT 
  i.id AS issue_id,
  i.subject,
  t.name AS tracker_name,
  s.name AS current_status,
  COUNT(w.id) AS available_transitions
FROM 
  issues i
JOIN 
  trackers t ON i.tracker_id = t.id
JOIN 
  issue_statuses s ON i.status_id = s.id
LEFT JOIN 
  workflows w ON i.tracker_id = w.tracker_id AND i.status_id = w.old_status_id
WHERE 
  i.id = 93
GROUP BY 
  i.id, i.subject, t.name, s.name;

-- Check available transitions for issue #93 grouped by role
SELECT 
  r.name AS role_name,
  s.name AS current_status,
  COUNT(DISTINCT w.new_status_id) AS possible_transitions,
  GROUP_CONCAT(DISTINCT target.name ORDER BY target.name SEPARATOR ', ') AS target_statuses
FROM 
  issues i
JOIN 
  trackers t ON i.tracker_id = t.id
JOIN 
  issue_statuses s ON i.status_id = s.id
JOIN 
  roles r ON r.id > 0
LEFT JOIN 
  workflows w ON i.tracker_id = w.tracker_id 
                AND i.status_id = w.old_status_id
                AND r.id = w.role_id
LEFT JOIN
  issue_statuses target ON w.new_status_id = target.id
WHERE 
  i.id = 93
GROUP BY 
  r.name, s.name
ORDER BY 
  r.name;

-- Check specific role capabilities
SELECT 
  r.name AS role_name,
  COUNT(DISTINCT w.old_status_id) AS from_statuses,
  COUNT(DISTINCT w.new_status_id) AS to_statuses,
  COUNT(*) AS total_transitions
FROM 
  roles r
JOIN 
  workflows w ON r.id = w.role_id
JOIN 
  trackers t ON w.tracker_id = t.id
WHERE 
  t.name = 'Feature'
GROUP BY 
  r.name
ORDER BY 
  total_transitions DESC;

-- Detailed workflow matrix for our newly created 'WorkflowManager' role (if it exists)
SELECT 
  t.name AS tracker_name,
  old.name AS from_status,
  new.name AS to_status,
  'WorkflowManager' AS role_name
FROM 
  roles r
JOIN 
  workflows w ON r.id = w.role_id
JOIN 
  trackers t ON w.tracker_id = t.id
JOIN 
  issue_statuses old ON w.old_status_id = old.id
JOIN 
  issue_statuses new ON w.new_status_id = new.id
WHERE 
  r.name = 'WorkflowManager'
ORDER BY 
  t.name, old.name, new.name;

-- Final check: Can Redmine API user (id=1) update issue #93 from New to Closed?
SELECT 
  CASE 
    WHEN EXISTS (
      SELECT 1 
      FROM workflows w
      WHERE w.tracker_id = (SELECT tracker_id FROM issues WHERE id = 93)
      AND w.role_id IN (SELECT mr.role_id FROM members m JOIN member_roles mr ON m.id = mr.member_id WHERE m.user_id = 1)
      AND w.old_status_id = (SELECT status_id FROM issues WHERE id = 93)
      AND w.new_status_id = (SELECT id FROM issue_statuses WHERE name = 'Closed')
    ) THEN 'YES - Admin can update issue #93 to Closed directly'
    ELSE 'NO - Admin must follow workflow path to close issue #93'
  END AS can_admin_close_issue;
