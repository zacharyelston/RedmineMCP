-- 02_associate_with_project.sql
-- Associate trackers with the MCP project
-- Part of the ModelContextProtocol (MCP) Implementation

-- Associate MCP Documentation tracker with the project
INSERT INTO projects_trackers (project_id, tracker_id)
SELECT 
  (SELECT id FROM projects WHERE identifier = 'mcp-project'),
  (SELECT id FROM trackers WHERE name = 'MCP Documentation')
WHERE 
  EXISTS (SELECT 1 FROM projects WHERE identifier = 'mcp-project') AND
  EXISTS (SELECT 1 FROM trackers WHERE name = 'MCP Documentation') AND
  NOT EXISTS (
    SELECT 1 FROM projects_trackers 
    WHERE project_id = (SELECT id FROM projects WHERE identifier = 'mcp-project') 
    AND tracker_id = (SELECT id FROM trackers WHERE name = 'MCP Documentation')
  );
  
-- Associate MCP Test Case tracker with the project
INSERT INTO projects_trackers (project_id, tracker_id)
SELECT 
  (SELECT id FROM projects WHERE identifier = 'mcp-project'),
  (SELECT id FROM trackers WHERE name = 'MCP Test Case')
WHERE 
  EXISTS (SELECT 1 FROM projects WHERE identifier = 'mcp-project') AND
  EXISTS (SELECT 1 FROM trackers WHERE name = 'MCP Test Case') AND
  NOT EXISTS (
    SELECT 1 FROM projects_trackers 
    WHERE project_id = (SELECT id FROM projects WHERE identifier = 'mcp-project') 
    AND tracker_id = (SELECT id FROM trackers WHERE name = 'MCP Test Case')
  );