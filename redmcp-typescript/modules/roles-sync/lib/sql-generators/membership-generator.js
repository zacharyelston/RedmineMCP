/**
 * membership-generator.js
 * 
 * Generates SQL for creating project memberships for role-based users
 */

/**
 * Generate SQL for creating project memberships based on role configuration
 * 
 * @param {Object} config - The role configuration object
 * @returns {string} SQL statements for creating project memberships
 */
function generateMembershipSql(config) {
  const { role, mcp_server_config } = config;
  
  // Create a base login name from the role name
  const baseLogin = role.name.toLowerCase().replace(/\s+/g, '_');
  const userLogin = `${baseLogin}_agent`;
  
  // Define project access - either all projects or specific projects
  const projectAccess = mcp_server_config.project_access || 'all';
  
  let sql = `
-- Create project memberships for the ${role.name} role user
-- First, get the user ID again to ensure it's set
SET @user_id = (SELECT id FROM users WHERE login = '${userLogin}');
`;

  // Handle different project access configurations
  if (projectAccess === 'all') {
    // Add this user to all projects with this role
    sql += `
-- Add this user to all projects with the ${role.name} role
INSERT INTO members (user_id, project_id, created_on, mail_notification)
SELECT 
  @user_id, 
  p.id, 
  NOW(), 
  FALSE
FROM 
  projects p
WHERE 
  p.status = 1 -- Only active projects
  AND NOT EXISTS (
    SELECT 1 FROM members WHERE user_id = @user_id AND project_id = p.id
  );

-- Now add the role to all memberships for this user
INSERT INTO member_roles (member_id, role_id)
SELECT 
  m.id, 
  @role_id
FROM 
  members m
WHERE 
  m.user_id = @user_id
  AND NOT EXISTS (
    SELECT 1 FROM member_roles 
    WHERE member_id = m.id 
    AND role_id = @role_id
  );

-- Count the number of projects this user has access to
SELECT 
  COUNT(DISTINCT p.id) AS project_count,
  CONCAT('User ${userLogin} has been granted access to ', COUNT(DISTINCT p.id), ' projects with the ${role.name} role') AS result
FROM 
  projects p
JOIN 
  members m ON p.id = m.project_id
JOIN 
  member_roles mr ON m.id = mr.member_id
WHERE 
  m.user_id = @user_id
  AND mr.role_id = @role_id;`;
  } else if (Array.isArray(projectAccess)) {
    // Add this user only to specific projects
    const projectIdList = projectAccess.join(', ');
    
    sql += `
-- Add this user only to specified projects: ${projectIdList}
INSERT INTO members (user_id, project_id, created_on, mail_notification)
SELECT 
  @user_id, 
  p.id, 
  NOW(), 
  FALSE
FROM 
  projects p
WHERE 
  p.id IN (${projectIdList})
  AND p.status = 1 -- Only active projects
  AND NOT EXISTS (
    SELECT 1 FROM members WHERE user_id = @user_id AND project_id = p.id
  );

-- Now add the role to these specific memberships
INSERT INTO member_roles (member_id, role_id)
SELECT 
  m.id, 
  @role_id
FROM 
  members m
JOIN
  projects p ON m.project_id = p.id
WHERE 
  m.user_id = @user_id
  AND p.id IN (${projectIdList})
  AND NOT EXISTS (
    SELECT 1 FROM member_roles 
    WHERE member_id = m.id 
    AND role_id = @role_id
  );

-- Verify project access
SELECT 
  p.id AS project_id,
  p.name AS project_name,
  m.id AS membership_id,
  mr.role_id
FROM 
  projects p
JOIN 
  members m ON p.id = m.project_id
JOIN 
  member_roles mr ON m.id = mr.member_id
WHERE 
  m.user_id = @user_id
  AND mr.role_id = @role_id
  AND p.id IN (${projectIdList});`;
  } else if (typeof projectAccess === 'object' && projectAccess.identifiers) {
    // Add this user to projects based on identifiers
    const projectIdentifiers = projectAccess.identifiers
      .map(identifier => `'${identifier}'`)
      .join(', ');
    
    sql += `
-- Add this user to projects with specified identifiers: ${projectIdentifiers}
INSERT INTO members (user_id, project_id, created_on, mail_notification)
SELECT 
  @user_id, 
  p.id, 
  NOW(), 
  FALSE
FROM 
  projects p
WHERE 
  p.identifier IN (${projectIdentifiers})
  AND p.status = 1 -- Only active projects
  AND NOT EXISTS (
    SELECT 1 FROM members WHERE user_id = @user_id AND project_id = p.id
  );

-- Now add the role to these specific memberships
INSERT INTO member_roles (member_id, role_id)
SELECT 
  m.id, 
  @role_id
FROM 
  members m
JOIN
  projects p ON m.project_id = p.id
WHERE 
  m.user_id = @user_id
  AND p.identifier IN (${projectIdentifiers})
  AND NOT EXISTS (
    SELECT 1 FROM member_roles 
    WHERE member_id = m.id 
    AND role_id = @role_id
  );

-- Verify project access
SELECT 
  p.id AS project_id,
  p.name AS project_name,
  p.identifier AS project_identifier,
  m.id AS membership_id,
  mr.role_id
FROM 
  projects p
JOIN 
  members m ON p.id = m.project_id
JOIN 
  member_roles mr ON m.id = mr.member_id
WHERE 
  m.user_id = @user_id
  AND mr.role_id = @role_id
  AND p.identifier IN (${projectIdentifiers});`;
  }
  
  return sql;
}

module.exports = {
  generateMembershipSql
};
