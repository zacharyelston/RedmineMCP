# Redmine MCP Server - Process Documentation

## Core Principles

1. **Process Over Speed**: Careful, methodical progress is valued over rapid development
2. **One Task at a Time**: Complete focus on a single task until it is fully validated
3. **Validation Gates**: No task is considered complete until it passes all validation steps
4. **Documentation First**: Document what will be done before doing it
5. **Security Through Repetition**: Consistent processes reduce error and security risks
6. **Evidence-Based Progress**: All progress must be evidenced and documented

## Task Lifecycle

### 1. Task Identification

- Document the task in detail
- Assign a unique task ID (format: RMCP-YYYYMMDD-XX)
- Store task documentation in `redmine-mcp/tasks/[task-id].md`

### 2. Task Analysis

- Break down the task into atomic steps
- Identify dependencies and prerequisites
- Define acceptance criteria for each step
- Identify potential risks and mitigations
- Document all analysis in the task file

### 3. Task Documentation

- Create document template from `redmine-mcp/templates/task_template.md`
- Document the implementation approach
- Define test cases
- Define validation steps
- Review and approve documentation

### 4. Implementation

- Follow the documented approach exactly
- Document any deviations from the plan
- Document issues encountered
- Store implementation in the appropriate location in the code repository

### 5. Testing

- Execute defined test cases
- Document test results
- Store test evidence in `redmine-mcp/validation/evidence/[task-id]/`
- If tests fail, return to Implementation step

### 6. Validation

- Complete the validation checklist
- Document validation steps taken
- Store validation evidence
- If validation fails, return to Implementation step

### 7. Review

- Present completed task for review
- Document review feedback
- Make requested adjustments
- If significant changes are needed, return to Implementation step

### 8. Completion

- Update task status to complete
- Document lessons learned
- Update project documentation
- Update project plan

## MCP Validation Protocol

Every MCP-related component must undergo the ModelContextProtocol validation process:

1. **Schema Validation**: Ensure all data structures conform to MCP schema specifications
2. **Protocol Compliance**: Verify all interactions follow MCP protocol requirements
3. **Security Verification**: Check for security vulnerabilities specific to MCP
4. **Performance Testing**: Verify performance meets MCP operational requirements
5. **Documentation Review**: Ensure all MCP components are properly documented

## Change Management Process

1. **Change Request**: Document proposed change using the change request template
2. **Impact Analysis**: Analyze impact of the change on system and processes
3. **Approval**: Get explicit approval for the change
4. **Implementation**: Implement the change according to the regular task process
5. **Verification**: Verify the change was correctly implemented
6. **Documentation**: Update all affected documentation

## Error Handling Protocol

1. **Error Documentation**: Document the error encountered in detail
2. **Root Cause Analysis**: Determine the underlying cause
3. **Process Review**: Identify if a process weakness contributed to the error
4. **Correction**: Implement a correction
5. **Verification**: Verify the correction resolves the issue
6. **Process Improvement**: Update processes to prevent similar errors

## Code Repository Management

1. **Branching Model**:
   - `main`: Stable, production-ready code
   - `develop`: Integration branch for feature development
   - `feature/[task-id]`: Individual feature branches

2. **Commit Protocol**:
   - Prefix all commits with task ID
   - Use descriptive commit messages
   - Include reference to documentation

3. **Merge Requirements**:
   - All tests must pass
   - Documentation must be complete
   - Code review must be complete
   - Validation must be successful

## Documentation Standards

1. **Format**: All documentation in Markdown format
2. **Structure**: Follow templates provided
3. **Naming Convention**: Use consistent file naming (lowercase, hyphens for spaces)
4. **Version Control**: Document version history in each file
5. **Cross-References**: Use internal links to reference related documentation

*Remember: How slowly you work is an indication of how careful you are. Process is the key and provides security through repetition.*