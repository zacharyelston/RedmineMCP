# Developer Guide - Redmine MCP Extension

This guide establishes the development processes and procedures for the Redmine MCP Extension project. All team members must adhere to these guidelines to ensure code quality, traceability, and effective collaboration.

## Core Development Principles

1. **Issue-Driven Development**: No code is written without a corresponding issue
2. **Branch Isolation**: Each issue is addressed in its own dedicated branch
3. **Scope Management**: Unrelated changes are moved to separate issues
4. **Traceability**: All work must be traceable back to requirements
5. **Process Over Speed**: Follow the process even when a quick fix seems tempting
6. **Leverage Existing Tools**: Use established tools instead of reinventing the wheel
7. **Simplicity First**: Prefer simple solutions that work over complex custom implementations

## Development Workflow

### 1. Issue Creation and Management

Every development task begins with an issue. No exceptions.

#### Creating a New Issue

1. Review the TODO.md file to identify the requirement or bug
2. Create a new issue in the repository's issue tracker with:
   - Clear, concise title that summarizes the work
   - Detailed description of the requirement/bug
   - Acceptance criteria that define when the issue is complete
   - Links to related documentation or other issues
   - Appropriate labels (bug, enhancement, documentation, etc.)
   - Priority and estimated effort
3. Assign the issue to yourself or the appropriate team member
4. Update TODO.md to reference the issue number

```
Example issue:
Title: Fix 403 Forbidden error when creating Redmine trackers
Description: When bootstrapping a new Redmine instance, trackers cannot be 
created due to a 403 Forbidden error. This needs to be fixed to enable proper 
testing and development workflows.
Acceptance Criteria:
- Bootstrap script can create trackers without 403 errors
- All three default trackers (Bug, Feature, Support) are created successfully
- Tests pass consistently in CI environment
```

#### Issue Management Guidelines

- Keep issues focused on a single concern
- If you discover additional work needed during development, create a new issue rather than expanding the scope
- Follow the "Definition of Ready" before starting work:
  - Issue is fully described with clear acceptance criteria
  - Issue is correctly prioritized and estimated
  - Dependencies are identified and resolved or noted

### 2. Branch Creation and Management

Once an issue is ready for development, create a dedicated branch.

#### Creating a Branch

1. Ensure you're starting from the latest version of the main branch:
   ```bash
   git checkout main
   git pull origin main
   ```

2. Create a new branch with a naming convention that includes the issue number:
   ```bash
   # For bug fixes
   git checkout -b fix/ISSUE_NUMBER-brief-description
   
   # For features
   git checkout -b feature/ISSUE_NUMBER-brief-description
   
   # Example:
   git checkout -b fix/19-redmine-trackers
   ```

3. Push the branch to the remote repository immediately:
   ```bash
   git push -u origin fix/19-redmine-trackers
   ```

#### Branch Guidelines

- Never work directly on the main branch
- One issue per branch, one branch per issue
- Keep branches short-lived (aim for 1-3 days)
- Rebase regularly to stay current with main

### 3. Development Process

With the issue created and branch established, development can begin.

#### Development Steps

1. Set up your local development environment:
   ```bash
   # Start the development environment with Docker
   docker-compose -f docker-compose.local.yml up -d
   
   # Verify services are running
   docker ps
   ```

2. Implement the changes required to address the issue
   - Write code that directly addresses the issue's acceptance criteria
   - Add tests to verify the functionality
   - Document the changes in code comments

3. **Scope Management**: If you discover needed changes outside the issue scope:
   - Stop work on the unrelated change
   - Create a new issue for the discovered work
   - Add the item to TODO.md in the appropriate section
   - Return focus to the original issue

4. Run tests locally:
   ```bash
   # Run API tests
   python scripts/test_redmine_api_functionality.py
   
   # Run other applicable tests for your changes
   ```

#### Tooling Guidelines

1. **Use Existing Tools**: Before creating a new script or tool, check if an existing solution already exists:
   - Use built-in Docker commands (`docker ps`, `docker-compose logs`) instead of creating wrapper scripts
   - Leverage existing libraries rather than writing custom implementations
   - Search the repository for existing utilities before writing new ones

2. **Simple Over Complex**:
   - Prefer command-line tools over GUI solutions for automation
   - Use simple shell commands and existing scripts when possible
   - Keep custom scripts focused and minimal – single responsibility principle

3. **Documentation Over Code**: Sometimes a well-documented manual process is better than an automated one that's hard to maintain:
   - Document procedures clearly in markdown
   - Provide example commands for infrequent operations rather than creating scripts
   - Reserve coding effort for repeated, complex tasks only

#### Commit Guidelines

Commits should be atomic, focused, and traceable.

1. Stage only related changes:
   ```bash
   # Review changes before staging
   git status
   
   # Stage specific files
   git add path/to/changed/file.py
   
   # Review what's been staged
   git diff --staged
   ```

2. Create a descriptive commit message that references the issue:
   ```bash
   git commit -m "#19: Fix Redmine tracker permission issues by adding admin authentication"
   ```

3. Push changes to your branch:
   ```bash
   git push
   ```

### 4. Testing and Validation

Before submitting your work for review, ensure it meets quality standards.

#### Testing Requirements

1. All existing tests pass
2. New tests cover the added functionality
3. The code works in the development environment
4. Acceptance criteria are fully satisfied

#### Validation Steps

1. Run the full test suite:
   ```bash
   # Run full test suite
   python -m pytest
   ```

2. Verify the fix resolves the issue:
   ```bash
   # Example: test the tracker creation
   python scripts/bootstrap_redmine.py
   ```

3. Document your testing in the issue comments

### 5. Code Review and Pull Request

Once development and testing are complete, submit your work for review.

#### Creating a Pull Request

1. Push your final changes:
   ```bash
   git push origin fix/19-redmine-trackers
   ```

2. Create a pull request with:
   - Clear title referencing the issue
   - Description of the changes made
   - Testing performed
   - Screenshots/evidence of the fix working
   - Any notes for reviewers

3. Link the PR to the issue

#### Code Review Process

1. At least one team member must review the PR
2. Automated tests must pass in CI
3. Review comments must be addressed with follow-up commits
4. Final approval required before merging

### 6. Merging and Deployment

After approval, changes can be merged and deployed.

#### Merge Process

1. Ensure the branch is up-to-date with main:
   ```bash
   git checkout fix/19-redmine-trackers
   git pull origin main
   git push
   ```

2. Merge the PR through the repository interface
3. Delete the branch after successful merge

#### Post-Merge Actions

1. Update the issue status to "Closed"
2. Update TODO.md to mark the item as completed
3. Document any relevant information in project documentation

## Example Workflow: Fixing the Redmine Trackers Issue

Let's walk through a concrete example of addressing issue #19 for fixing Redmine tracker permission problems.

### Step 1: Issue Review

1. Review issue #19 about Redmine tracker permissions
2. Verify the issue description and acceptance criteria are clear
3. Confirm the issue is prioritized correctly in TODO.md

### Step 2: Branch Creation

```bash
git checkout main
git pull
git checkout -b fix/19-redmine-trackers
git push -u origin fix/19-redmine-trackers
```

### Step 3: Investigation and Development

1. Set up the development environment:
   ```bash
   docker-compose -f docker-compose.local.yml up -d
   docker ps  # Verify services are running
   ```

2. Investigate the issue:
   - Use existing tools to diagnose the issue:
     ```bash
     # Check container logs
     docker-compose logs redmine
     
     # Test API access directly with curl
     curl -H "X-Redmine-API-Key: your_api_key" http://localhost:3000/trackers.json
     ```
   - Identify that the 403 Forbidden error is caused by insufficient permissions

3. Implement the solution:
   - Use the simplest approach that works: modify existing files rather than creating new ones
   - Modify the redmine_api.py file to properly handle authentication
   - Add error handling for permission issues
   - Test the solution incrementally

### Step 4: Commit Changes

```bash
git add redmine_api.py
git commit -m "#19: Fix authentication in Redmine API client to prevent 403 errors"

git add scripts/bootstrap_redmine.py
git commit -m "#19: Update bootstrap script to handle admin authentication for tracker creation"
```

### Step 5: Testing

```bash
# Test the fix
python scripts/bootstrap_redmine.py

# Verify trackers are created
python scripts/test_redmine_api_functionality.py
```

### Step 6: Submit PR and Complete

1. Create pull request for fix/19-redmine-trackers
2. Get approval from team
3. Merge changes
4. Close issue #19
5. Update TODO.md to mark the item as completed

## Documentation and Communication

### Documentation Requirements

- Code changes must be documented with clear comments
- API changes require updated API documentation
- User-facing changes need appropriate user documentation updates
- Complex solutions should include architecture or design documentation

### Communication Guidelines

- Provide regular updates on issue progress
- Document roadblocks or challenges in the issue comments
- Ask for help early when stuck, don't waste time on solved problems
- Share knowledge and lessons learned with the team

## Anti-Patterns to Avoid

1. **Over-Engineering**: Don't create complex solutions when simple ones will do
   - Example: Writing a custom wrapper script around Docker commands when direct Docker commands work fine
   - Better approach: Document the Docker commands to use and their parameters

2. **Not Invented Here Syndrome**: Avoid recreating tools that already exist
   - Example: Writing a custom test runner instead of using pytest
   - Better approach: Configure existing tools to meet your specific needs

3. **Too Many Dependencies**: Beware of adding numerous external libraries
   - Example: Adding multiple specialized libraries for simple tasks
   - Better approach: Use the standard library when it suffices; only add dependencies for complex functionality

4. **Obscured Documentation**: Avoid burying important procedures in code
   - Example: Creating complex automation that's hard to understand and maintain
   - Better approach: Document procedures clearly and automate only what's repeatedly used

## Conclusion

Following this process ensures our development efforts are:
- Traceable to requirements
- Properly reviewed and tested
- Well-documented
- Maintainable in the long term
- Focused on simplicity and reuse rather than reinventing solutions

Remember: Process and traceability lead to quality and maintainability. Speed is a byproduct of a good process, not a substitute for it. Use the simplest tools that get the job done effectively.
