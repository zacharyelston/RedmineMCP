-- check_created_issues.sql
-- Script to check the issues created in Redmine
-- Part of the ModelContextProtocol (MCP) Implementation

-- Check the issues table for newly created issues
SELECT id, project_id, tracker_id, subject, status_id, priority_id, author_id, created_on
FROM issues
ORDER BY id;

-- Get more detailed information about the issues
SELECT i.id, i.subject, 
       p.name as project_name, 
       t.name as tracker_name,
       s.name as status_name,
       e.name as priority_name,
       u.login as author
FROM issues i
JOIN projects p ON i.project_id = p.id
JOIN trackers t ON i.tracker_id = t.id
JOIN issue_statuses s ON i.status_id = s.id
JOIN enumerations e ON i.priority_id = e.id
JOIN users u ON i.author_id = u.id
ORDER BY i.id;
