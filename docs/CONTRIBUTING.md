# Contributing to Redmine MCP Server

Thank you for your interest in contributing to the Redmine MCP Server project! This document outlines our contribution process and guidelines.

## Core Principles

Our development process is guided by these core principles:

1. **Process Over Speed**: We value careful, methodical progress over rapid development
2. **Validation Gates**: All work must pass through validation gates before being considered complete
3. **Documentation First**: Document what will be done before doing it
4. **Security Through Repetition**: Consistent processes reduce error and security risks
5. **Evidence-Based Progress**: All progress must be evidenced and documented

## Contribution Process

### 1. Task Selection

- Review the project [TODO.md](TODO.md) file for current project priorities
- Identify a task that matches your skills and interests
- Verify that the task is not already being worked on by checking with the project maintainers

### 2. Task Documentation

- Create a new task document using the template in `templates/task_template.md`
- Assign a unique task ID (format: RMCP-YYYYMMDD-XX)
- Document the task in detail, including:
  - Clear objectives
  - Specific requirements
  - Implementation approach
  - Test cases
  - Risk assessment

### 3. Implementation

- Create a feature branch with the format `feature/[task-id]`
- Follow the documented approach exactly
- Document any deviations from the plan
- Write comprehensive tests for your implementation
- Ensure your code follows the project's coding standards

### 4. Testing

- Execute all defined test cases
- Document test results
- If tests fail, fix the issues and retest
- Store test evidence in the validation directory

### 5. Documentation

- Update relevant documentation to reflect your changes
- Document any new functionality, APIs, or processes
- Ensure all code is well-commented

### 6. Submission

- Create a pull request to the `develop` branch
- Reference the task ID in the pull request title
- Include a detailed description of the changes
- Attach validation evidence
- Request a review from project maintainers

### 7. Review Process

- Maintainers will review the code for:
  - Adherence to requirements
  - Code quality and standards
  - Test coverage
  - Documentation completeness
- Address any feedback provided during the review
- If significant changes are needed, the process may return to the implementation step

### 8. Validation

- Once approved, the validation process will be completed
- A validation document will be created
- The task will be marked as complete in the task tracking system

## Development Guidelines

### Code Standards

- Follow consistent coding standards
- Include appropriate inline documentation
- Write clear, self-explanatory code
- Follow the Ruby style guide

### Testing Requirements

- All new features must have test coverage
- All bug fixes must include regression tests
- Tests must be automated and repeatable

### Documentation Requirements

- All APIs must be documented
- All processes must be documented
- All configuration options must be documented
- Documentation must be kept up-to-date with code changes

### Security Considerations

- All code must follow security best practices
- Input validation must be comprehensive
- Authentication and authorization must be properly implemented
- Sensitive data must be handled securely

## Communication

- For general questions, open a discussion in the project repository
- For bug reports, create an issue with the tag 'bug'
- For feature requests, create an issue with the tag 'enhancement'
- For security issues, please see our [SECURITY.md](SECURITY.md) file

## License

By contributing to this project, you agree that your contributions will be licensed under the project's [LICENSE](LICENSE) file.

## Code of Conduct

Please read our [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) before contributing to the project. We expect all contributors to adhere to this code of conduct.

Thank you for contributing to Redmine MCP Server!
