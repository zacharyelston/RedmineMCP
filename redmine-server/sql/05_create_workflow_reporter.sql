-- 05_create_workflow_reporter.sql
-- Set up workflow for Reporter role
-- Part of the ModelContextProtocol (MCP) Implementation

-- Set up workflow for MCP Documentation tracker - Reporter role
INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
SELECT 
  (SELECT id FROM trackers WHERE name = 'MCP Documentation'),
  (SELECT id FROM roles WHERE name = 'Reporter'),
  (SELECT id FROM issue_statuses WHERE name = 'New'),
  (SELECT id FROM issue_statuses WHERE name = 'Feedback')
WHERE NOT EXISTS (
  SELECT 1 FROM workflows 
  WHERE tracker_id = (SELECT id FROM trackers WHERE name = 'MCP Documentation')
  AND role_id = (SELECT id FROM roles WHERE name = 'Reporter')
  AND old_status_id = (SELECT id FROM issue_statuses WHERE name = 'New')
  AND new_status_id = (SELECT id FROM issue_statuses WHERE name = 'Feedback')
);

INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
SELECT 
  (SELECT id FROM trackers WHERE name = 'MCP Documentation'),
  (SELECT id FROM roles WHERE name = 'Reporter'),
  (SELECT id FROM issue_statuses WHERE name = 'Resolved'),
  (SELECT id FROM issue_statuses WHERE name = 'Feedback')
WHERE NOT EXISTS (
  SELECT 1 FROM workflows 
  WHERE tracker_id = (SELECT id FROM trackers WHERE name = 'MCP Documentation')
  AND role_id = (SELECT id FROM roles WHERE name = 'Reporter')
  AND old_status_id = (SELECT id FROM issue_statuses WHERE name = 'Resolved')
  AND new_status_id = (SELECT id FROM issue_statuses WHERE name = 'Feedback')
);