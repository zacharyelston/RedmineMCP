-- inspect_trackers.sql
-- Script to perform a deep inspection of the trackers table and related entities
-- Part of the ModelContextProtocol (MCP) Implementation

-- Get tracker table structure
\d trackers

-- Check for any NULL values in required fields
SELECT id, name, position, is_in_roadmap, fields_bits, description
FROM trackers
WHERE id IS NULL OR name IS NULL OR position IS NULL OR is_in_roadmap IS NULL;

-- Check for duplicate positions
SELECT position, COUNT(*) as count
FROM trackers
GROUP BY position
HAVING COUNT(*) > 1;

-- Check for missing project associations
SELECT t.id, t.name
FROM trackers t
LEFT JOIN projects_trackers pt ON t.id = pt.tracker_id
WHERE pt.project_id IS NULL;

-- Check for trackers with missing workflow definitions
SELECT t.id, t.name
FROM trackers t
LEFT JOIN workflows w ON t.id = w.tracker_id
WHERE w.id IS NULL;

-- Count workflow rules by tracker (should be more than 0)
SELECT t.id, t.name, COUNT(w.id) as workflow_count
FROM trackers t
LEFT JOIN workflows w ON t.id = w.tracker_id
GROUP BY t.id, t.name
ORDER BY workflow_count;

-- Check if 'fields_bits' is set correctly
-- In Redmine, fields_bits is a bitmap indicating which fields are used by this tracker
SELECT id, name, fields_bits
FROM trackers;

-- Check for other potential issues
SELECT * FROM trackers WHERE position < 1;
