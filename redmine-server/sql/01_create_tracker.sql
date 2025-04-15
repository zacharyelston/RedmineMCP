-- 01_create_tracker.sql
-- Create a tracker with proper default_status_id
-- Part of the ModelContextProtocol (MCP) Implementation

-- Create MCP Documentation tracker with proper default status
INSERT INTO trackers (name, position, is_in_roadmap, fields_bits, description, default_status_id)
VALUES ('MCP Documentation', 
        (SELECT COALESCE(MAX(position), 0) + 1 FROM trackers),
        TRUE,
        0,
        'Documentation for ModelContextProtocol (MCP) implementation',
        (SELECT id FROM issue_statuses WHERE name = 'New'))
ON CONFLICT (name) DO NOTHING;

-- Create MCP Test Case tracker with proper default status
INSERT INTO trackers (name, position, is_in_roadmap, fields_bits, description, default_status_id)
VALUES ('MCP Test Case', 
        (SELECT COALESCE(MAX(position), 0) + 1 FROM trackers),
        TRUE,
        0,
        'Test cases for ModelContextProtocol (MCP) implementation',
        (SELECT id FROM issue_statuses WHERE name = 'New'))
ON CONFLICT (name) DO NOTHING;
