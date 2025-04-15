-- V12__Create_Trackers.sql
-- Create trackers for Redmine MCP
-- Part of the ModelContextProtocol (MCP) Implementation

-- Create Bug tracker if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM trackers WHERE name = 'Bug') THEN
    INSERT INTO trackers (name, position, is_in_roadmap, fields_bits, description)
    VALUES ('Bug', 1, FALSE, 0, 'Bugs and defects that need to be fixed');
  END IF;
END $$;

-- Create Feature tracker if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM trackers WHERE name = 'Feature') THEN
    INSERT INTO trackers (name, position, is_in_roadmap, fields_bits, description)
    VALUES ('Feature', 2, TRUE, 0, 'New features to be implemented');
  END IF;
END $$;

-- Create Support tracker if it doesn't exist
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM trackers WHERE name = 'Support') THEN
    INSERT INTO trackers (name, position, is_in_roadmap, fields_bits, description)
    VALUES ('Support', 3, FALSE, 0, 'Support requests from users');
  END IF;
END $$;

-- Update existing trackers with descriptions if they exist
UPDATE trackers SET description = 'Regular task to be completed' WHERE name = 'Task';
UPDATE trackers SET description = 'Large features that contain multiple stories' WHERE name = 'Epic';
UPDATE trackers SET description = 'User story describing functionality from user perspective' WHERE name = 'Story';

-- Ensure all trackers are associated with our project
DO $$
DECLARE
  v_project_id INTEGER;
  v_tracker_id INTEGER;
  tracker_cursor CURSOR FOR SELECT id FROM trackers;
BEGIN
  -- Get project ID
  SELECT id INTO v_project_id FROM projects WHERE identifier = 'mcp-project';

  -- Associate all trackers with the project
  IF v_project_id IS NOT NULL THEN
    OPEN tracker_cursor;
    LOOP
      FETCH tracker_cursor INTO v_tracker_id;
      EXIT WHEN NOT FOUND;
      
      -- Check if association already exists
      IF NOT EXISTS (SELECT 1 FROM projects_trackers 
                     WHERE project_id = v_project_id AND tracker_id = v_tracker_id) THEN
        -- Create association
        INSERT INTO projects_trackers (project_id, tracker_id)
        VALUES (v_project_id, v_tracker_id);
      END IF;
    END LOOP;
    CLOSE tracker_cursor;
  END IF;
END $$;
