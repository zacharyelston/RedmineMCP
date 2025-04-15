-- 04_create_workflow_manager.sql
-- Set up workflow for Manager role
-- Part of the ModelContextProtocol (MCP) Implementation

-- Set up workflow for MCP Documentation tracker - Manager role
INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
SELECT 
  (SELECT id FROM trackers WHERE name = 'MCP Documentation'),
  (SELECT id FROM roles WHERE name = 'Manager'),
  (SELECT id FROM issue_statuses WHERE name = 'New'),
  (SELECT id FROM issue_statuses WHERE name = 'In Progress')
WHERE NOT EXISTS (
  SELECT 1 FROM workflows 
  WHERE tracker_id = (SELECT id FROM trackers WHERE name = 'MCP Documentation')
  AND role_id = (SELECT id FROM roles WHERE name = 'Manager')
  AND old_status_id = (SELECT id FROM issue_statuses WHERE name = 'New')
  AND new_status_id = (SELECT id FROM issue_statuses WHERE name = 'In Progress')
);

INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
SELECT 
  (SELECT id FROM trackers WHERE name = 'MCP Documentation'),
  (SELECT id FROM roles WHERE name = 'Manager'),
  (SELECT id FROM issue_statuses WHERE name = 'Resolved'),
  (SELECT id FROM issue_statuses WHERE name = 'Closed')
WHERE NOT EXISTS (
  SELECT 1 FROM workflows 
  WHERE tracker_id = (SELECT id FROM trackers WHERE name = 'MCP Documentation')
  AND role_id = (SELECT id FROM roles WHERE name = 'Manager')
  AND old_status_id = (SELECT id FROM issue_statuses WHERE name = 'Resolved')
  AND new_status_id = (SELECT id FROM issue_statuses WHERE name = 'Closed')
);

-- Set up workflow for MCP Test Case tracker - Manager role
INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
SELECT 
  (SELECT id FROM trackers WHERE name = 'MCP Test Case'),
  (SELECT id FROM roles WHERE name = 'Manager'),
  (SELECT id FROM issue_statuses WHERE name = 'New'),
  (SELECT id FROM issue_statuses WHERE name = 'In Progress')
WHERE NOT EXISTS (
  SELECT 1 FROM workflows 
  WHERE tracker_id = (SELECT id FROM trackers WHERE name = 'MCP Test Case')
  AND role_id = (SELECT id FROM roles WHERE name = 'Manager')
  AND old_status_id = (SELECT id FROM issue_statuses WHERE name = 'New')
  AND new_status_id = (SELECT id FROM issue_statuses WHERE name = 'In Progress')
);

INSERT INTO workflows (tracker_id, role_id, old_status_id, new_status_id)
SELECT 
  (SELECT id FROM trackers WHERE name = 'MCP Test Case'),
  (SELECT id FROM roles WHERE name = 'Manager'),
  (SELECT id FROM issue_statuses WHERE name = 'Resolved'),
  (SELECT id FROM issue_statuses WHERE name = 'Closed')
WHERE NOT EXISTS (
  SELECT 1 FROM workflows 
  WHERE tracker_id = (SELECT id FROM trackers WHERE name = 'MCP Test Case')
  AND role_id = (SELECT id FROM roles WHERE name = 'Manager')
  AND old_status_id = (SELECT id FROM issue_statuses WHERE name = 'Resolved')
  AND new_status_id = (SELECT id FROM issue_statuses WHERE name = 'Closed')
);