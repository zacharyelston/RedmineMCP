-- V8__Create_Default_Project_Fixed2.sql
-- Default project creation for Redmine MCP
-- Part of the ModelContextProtocol (MCP) Implementation
-- Fixed version to properly set nested set values

-- Create a default MCP project if it doesn't exist
DO $$
DECLARE
  v_max_rgt INTEGER;
BEGIN
  -- Get the maximum right value to position the new project correctly
  SELECT COALESCE(MAX(rgt), 0) INTO v_max_rgt FROM projects;
  
  -- Insert the project with proper nested set values
  IF NOT EXISTS (SELECT 1 FROM projects WHERE identifier = 'mcp-project') THEN
    INSERT INTO projects (
      name, 
      description, 
      homepage, 
      is_public, 
      identifier, 
      status, 
      created_on, 
      updated_on, 
      inherit_members,
      lft,  -- Left value for nested set
      rgt   -- Right value for nested set
    )
    VALUES (
      'MCP Project', 
      'Default project for ModelContextProtocol (MCP) implementation.', 
      'http://modelcontextprotocol.io', 
      TRUE, 
      'mcp-project', 
      1, 
      NOW(), 
      NOW(), 
      FALSE,
      v_max_rgt + 1,  -- Left value is max right + 1
      v_max_rgt + 2   -- Right value is max right + 2
    );
  ELSE
    -- Update nested set values if they're NULL
    UPDATE projects
    SET lft = v_max_rgt + 1, rgt = v_max_rgt + 2
    WHERE identifier = 'mcp-project' AND (lft IS NULL OR rgt IS NULL);
  END IF;
END $$;

-- Enable modules for the project
DO $$
DECLARE
  v_project_id INTEGER;
BEGIN
  -- Get project ID
  SELECT id INTO v_project_id FROM projects WHERE identifier = 'mcp-project';
  
  -- Enable all modules for the project
  IF v_project_id IS NOT NULL THEN
    INSERT INTO enabled_modules (project_id, name)
    SELECT 
      v_project_id, 
      m.module_name
    FROM 
      (
        VALUES 
          ('issue_tracking'),
          ('time_tracking'),
          ('news'),
          ('documents'),
          ('files'),
          ('wiki'),
          ('repository'),
          ('boards'),
          ('calendar'),
          ('gantt')
      ) AS m(module_name)
    WHERE 
      NOT EXISTS (
        SELECT 1 
        FROM enabled_modules 
        WHERE project_id = v_project_id AND name = m.module_name
      );
    
    -- Create some initial versions
    IF NOT EXISTS (SELECT 1 FROM versions WHERE project_id = v_project_id AND name = '1.0') THEN
      INSERT INTO versions (
        project_id, 
        name, 
        description, 
        status, 
        sharing, 
        created_on, 
        updated_on
      )
      VALUES (
        v_project_id,
        '1.0',
        'Initial MCP version',
        'open',
        'none',
        NOW(),
        NOW()
      );
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM versions WHERE project_id = v_project_id AND name = '1.1') THEN
      INSERT INTO versions (
        project_id, 
        name, 
        description, 
        status, 
        sharing, 
        created_on, 
        updated_on
      )
      VALUES (
        v_project_id,
        '1.1',
        'First incremental update',
        'open',
        'none',
        NOW(),
        NOW()
      );
    END IF;
    
    -- Create issue categories
    IF NOT EXISTS (SELECT 1 FROM issue_categories WHERE project_id = v_project_id AND name = 'Backend') THEN
      INSERT INTO issue_categories (project_id, name)
      VALUES (v_project_id, 'Backend');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM issue_categories WHERE project_id = v_project_id AND name = 'Frontend') THEN
      INSERT INTO issue_categories (project_id, name)
      VALUES (v_project_id, 'Frontend');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM issue_categories WHERE project_id = v_project_id AND name = 'Documentation') THEN
      INSERT INTO issue_categories (project_id, name)
      VALUES (v_project_id, 'Documentation');
    END IF;
    
    IF NOT EXISTS (SELECT 1 FROM issue_categories WHERE project_id = v_project_id AND name = 'Infrastructure') THEN
      INSERT INTO issue_categories (project_id, name)
      VALUES (v_project_id, 'Infrastructure');
    END IF;
  END IF;
END $$;
