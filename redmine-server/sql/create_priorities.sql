-- create_priorities.sql
-- Script to create issue priorities in Redmine
-- Part of the ModelContextProtocol (MCP) Implementation

-- Create standard priorities if they don't exist
INSERT INTO enumerations (name, position, type)
VALUES ('Low', 1, 'IssuePriority')
ON CONFLICT DO NOTHING;

INSERT INTO enumerations (name, position, type)
VALUES ('Normal', 2, 'IssuePriority')
ON CONFLICT DO NOTHING;

INSERT INTO enumerations (name, position, type)
VALUES ('High', 3, 'IssuePriority')
ON CONFLICT DO NOTHING;

INSERT INTO enumerations (name, position, type)
VALUES ('Urgent', 4, 'IssuePriority')
ON CONFLICT DO NOTHING;

INSERT INTO enumerations (name, position, type)
VALUES ('Immediate', 5, 'IssuePriority')
ON CONFLICT DO NOTHING;

-- Verify the priorities were created
SELECT id, name, position, type
FROM enumerations
WHERE type = 'IssuePriority'
ORDER BY position;