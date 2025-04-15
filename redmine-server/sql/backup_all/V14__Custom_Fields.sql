-- V14__Custom_Fields.sql
-- Create custom fields for Redmine MCP
-- Part of the ModelContextProtocol (MCP) Implementation

-- Create custom field formats if they don't exist
INSERT INTO custom_field_formats (name)
SELECT 'string' WHERE NOT EXISTS (SELECT 1 FROM custom_field_formats WHERE name = 'string');

INSERT INTO custom_field_formats (name)
SELECT 'text' WHERE NOT EXISTS (SELECT 1 FROM custom_field_formats WHERE name = 'text');

INSERT INTO custom_field_formats (name)
SELECT 'int' WHERE NOT EXISTS (SELECT 1 FROM custom_field_formats WHERE name = 'int');

INSERT INTO custom_field_formats (name)
SELECT 'float' WHERE NOT EXISTS (SELECT 1 FROM custom_field_formats WHERE name = 'float');

INSERT INTO custom_field_formats (name)
SELECT 'list' WHERE NOT EXISTS (SELECT 1 FROM custom_field_formats WHERE name = 'list');

INSERT INTO custom_field_formats (name)
SELECT 'date' WHERE NOT EXISTS (SELECT 1 FROM custom_field_formats WHERE name = 'date');

INSERT INTO custom_field_formats (name)
SELECT 'bool' WHERE NOT EXISTS (SELECT 1 FROM custom_field_formats WHERE name = 'bool');

INSERT INTO custom_field_formats (name)
SELECT 'user' WHERE NOT EXISTS (SELECT 1 FROM custom_field_formats WHERE name = 'user');

INSERT INTO custom_field_formats (name)
SELECT 'version' WHERE NOT EXISTS (SELECT 1 FROM custom_field_formats WHERE name = 'version');

-- Create Issue Custom Fields
DO $$
DECLARE
  v_format_string_id INTEGER;
  v_format_int_id INTEGER;
  v_format_date_id INTEGER;
  v_format_list_id INTEGER;
  v_format_bool_id INTEGER;
  v_format_text_id INTEGER;
  v_format_user_id INTEGER;
  v_severity_id INTEGER;
  v_tracker_bug_id INTEGER;
  v_tracker_feature_id INTEGER;
  v_tracker_task_id INTEGER;
  v_tracker_support_id INTEGER;
  v_project_id INTEGER;
BEGIN
  -- Get format IDs
  SELECT id INTO v_format_string_id FROM custom_field_formats WHERE name = 'string';
  SELECT id INTO v_format_int_id FROM custom_field_formats WHERE name = 'int';
  SELECT id INTO v_format_date_id FROM custom_field_formats WHERE name = 'date';
  SELECT id INTO v_format_list_id FROM custom_field_formats WHERE name = 'list';
  SELECT id INTO v_format_bool_id FROM custom_field_formats WHERE name = 'bool';
  SELECT id INTO v_format_text_id FROM custom_field_formats WHERE name = 'text';
  SELECT id INTO v_format_user_id FROM custom_field_formats WHERE name = 'user';
  
  -- Get tracker IDs
  SELECT id INTO v_tracker_bug_id FROM trackers WHERE name = 'Bug';
  SELECT id INTO v_tracker_feature_id FROM trackers WHERE name = 'Feature';
  SELECT id INTO v_tracker_task_id FROM trackers WHERE name = 'Task';
  SELECT id INTO v_tracker_support_id FROM trackers WHERE name = 'Support';

  -- Get project ID
  SELECT id INTO v_project_id FROM projects WHERE identifier = 'mcp-project';

  -- 1. Severity custom field (for bug tracker)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'Severity') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'IssueCustomField', 'Severity', 'list', 
      E'Critical\nHigh\nMedium\nLow', 
      '', NULL, NULL, FALSE, TRUE, TRUE, 
      1, TRUE, 'Medium', TRUE, '{}', 'The severity level of the bug',
      TRUE
    )
    RETURNING id INTO v_severity_id;

    -- Associate with Bug tracker
    IF v_tracker_bug_id IS NOT NULL AND v_severity_id IS NOT NULL THEN
      INSERT INTO custom_fields_trackers (custom_field_id, tracker_id)
      VALUES (v_severity_id, v_tracker_bug_id);
    END IF;
  END IF;

  -- 2. Story Points custom field (for Feature and Task trackers)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'Story Points') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'IssueCustomField', 'Story Points', 'int', 
      NULL, 
      '', NULL, NULL, FALSE, TRUE, TRUE, 
      2, TRUE, '', TRUE, '{}', 'Estimated effort in story points (Fibonacci: 1,2,3,5,8,13)',
      TRUE
    )
    RETURNING id INTO v_severity_id;

    -- Associate with Feature tracker
    IF v_tracker_feature_id IS NOT NULL AND v_severity_id IS NOT NULL THEN
      INSERT INTO custom_fields_trackers (custom_field_id, tracker_id)
      VALUES (v_severity_id, v_tracker_feature_id);
    END IF;

    -- Associate with Task tracker
    IF v_tracker_task_id IS NOT NULL AND v_severity_id IS NOT NULL THEN
      INSERT INTO custom_fields_trackers (custom_field_id, tracker_id)
      VALUES (v_severity_id, v_tracker_task_id);
    END IF;
  END IF;

  -- 3. Due Date (customized display date for all issues)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'Target Date') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'IssueCustomField', 'Target Date', 'date', 
      NULL, 
      '', NULL, NULL, FALSE, TRUE, TRUE, 
      3, TRUE, '', TRUE, '{}', 'Target completion date',
      TRUE
    )
    RETURNING id INTO v_severity_id;

    -- Associate with all trackers (by setting is_for_all=TRUE above)
  END IF;

  -- 4. Environment custom field (for bug tracker)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'Environment') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'IssueCustomField', 'Environment', 'text', 
      NULL, 
      '', NULL, NULL, FALSE, TRUE, FALSE, 
      4, TRUE, '', TRUE, '{}', 'Environment details (OS, browser, etc.)',
      TRUE
    )
    RETURNING id INTO v_severity_id;

    -- Associate with Bug tracker
    IF v_tracker_bug_id IS NOT NULL AND v_severity_id IS NOT NULL THEN
      INSERT INTO custom_fields_trackers (custom_field_id, tracker_id)
      VALUES (v_severity_id, v_tracker_bug_id);
    END IF;
  END IF;

  -- 5. Support Category (for support tickets)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'Support Category') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'IssueCustomField', 'Support Category', 'list', 
      E'Technical\nAccess\nAccount\nBilling\nUsage\nOther', 
      '', NULL, NULL, FALSE, TRUE, FALSE, 
      5, TRUE, 'Technical', TRUE, '{}', 'Category of support request',
      TRUE
    )
    RETURNING id INTO v_severity_id;

    -- Associate with Support tracker
    IF v_tracker_support_id IS NOT NULL AND v_severity_id IS NOT NULL THEN
      INSERT INTO custom_fields_trackers (custom_field_id, tracker_id)
      VALUES (v_severity_id, v_tracker_support_id);
    END IF;
  END IF;

  -- 6. Affects Version (for bug tracker)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'Affects Version') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'IssueCustomField', 'Affects Version', 'string', 
      NULL, 
      '', NULL, NULL, FALSE, TRUE, FALSE, 
      6, TRUE, '', TRUE, '{}', 'Version where the bug was found',
      TRUE
    )
    RETURNING id INTO v_severity_id;

    -- Associate with Bug tracker
    IF v_tracker_bug_id IS NOT NULL AND v_severity_id IS NOT NULL THEN
      INSERT INTO custom_fields_trackers (custom_field_id, tracker_id)
      VALUES (v_severity_id, v_tracker_bug_id);
    END IF;
  END IF;

  -- 7. QA Approved (for bug and feature trackers)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'QA Approved') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'IssueCustomField', 'QA Approved', 'bool', 
      NULL, 
      '', NULL, NULL, FALSE, TRUE, FALSE, 
      7, TRUE, '0', TRUE, '{}', 'Approved by QA',
      TRUE
    )
    RETURNING id INTO v_severity_id;

    -- Associate with Bug tracker
    IF v_tracker_bug_id IS NOT NULL AND v_severity_id IS NOT NULL THEN
      INSERT INTO custom_fields_trackers (custom_field_id, tracker_id)
      VALUES (v_severity_id, v_tracker_bug_id);
    END IF;

    -- Associate with Feature tracker
    IF v_tracker_feature_id IS NOT NULL AND v_severity_id IS NOT NULL THEN
      INSERT INTO custom_fields_trackers (custom_field_id, tracker_id)
      VALUES (v_severity_id, v_tracker_feature_id);
    END IF;
  END IF;

  -- 8. Assigned Department (user custom field for project)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'Department') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'UserCustomField', 'Department', 'list', 
      E'Engineering\nQA\nSupport\nProduct\nMarketing\nSales\nManagement', 
      '', NULL, NULL, FALSE, TRUE, TRUE, 
      1, TRUE, 'Engineering', TRUE, '{}', 'Department the user belongs to',
      TRUE
    );
  END IF;

  -- 9. Project Priority (project custom field)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'Project Priority') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'ProjectCustomField', 'Project Priority', 'list', 
      E'Critical\nHigh\nMedium\nLow', 
      '', NULL, NULL, FALSE, TRUE, TRUE, 
      1, TRUE, 'Medium', TRUE, '{}', 'Priority level of the project',
      TRUE
    );
  END IF;

  -- 10. Project Lead (project custom field)
  IF NOT EXISTS (SELECT 1 FROM custom_fields WHERE name = 'Project Lead') THEN
    INSERT INTO custom_fields (
      type, name, field_format, possible_values, 
      regexp, min_length, max_length, is_required, is_filter, is_for_all, 
      position, searchable, default_value, visible, format_store, description,
      editable
    )
    VALUES (
      'ProjectCustomField', 'Project Lead', 'user', 
      NULL, 
      '', NULL, NULL, FALSE, TRUE, TRUE, 
      2, TRUE, '', TRUE, '{}', 'Lead person responsible for the project',
      TRUE
    );
  END IF;

END $$;