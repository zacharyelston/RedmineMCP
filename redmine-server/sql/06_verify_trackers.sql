-- 06_verify_trackers.sql
-- Verify that trackers are properly created and configured
-- Part of the ModelContextProtocol (MCP) Implementation

-- Show all trackers and their default status
SELECT t.id, t.name, t.description, t.position, t.is_in_roadmap, 
       t.default_status_id, s.name as default_status_name
FROM trackers t
LEFT JOIN issue_statuses s ON t.default_status_id = s.id
ORDER BY t.position;

-- Show tracker-project associations
SELECT p.identifier AS project, t.name AS tracker
FROM projects p
JOIN projects_trackers pt ON p.id = pt.project_id
JOIN trackers t ON pt.tracker_id = t.id
WHERE t.name IN ('MCP Documentation', 'MCP Test Case')
ORDER BY t.name;

-- Show workflow rules
SELECT t.name AS tracker, r.name AS role, 
       old_status.name AS old_status, new_status.name AS new_status
FROM workflows w
JOIN trackers t ON w.tracker_id = t.id
JOIN roles r ON w.role_id = r.id
JOIN issue_statuses old_status ON w.old_status_id = old_status.id
JOIN issue_statuses new_status ON w.new_status_id = new_status.id
WHERE t.name IN ('MCP Documentation', 'MCP Test Case')
AND w.type IS NULL
ORDER BY t.name, r.name, old_status.name;