# Redmine MCP Server - Credentials Guide

## Overview

This document explains how credentials are managed in the Redmine MCP Server project, particularly focusing on the `credentials.yaml` file used for validation against an existing Redmine instance.

## Credentials File Format

The `credentials.yaml` file is a YAML-formatted file located in the project root directory. It contains the following key-value pairs:

```yaml
redmine_api_key: [API_KEY]
redmine_url: [REDMINE_URL]
```

Where:
- `redmine_api_key` is your Redmine API access key
- `redmine_url` is the URL of your Redmine instance (e.g., http://localhost:3000)

## Development Environment Credentials

For development purposes, the project includes a development environment in the `redmine-server/` directory with predefined API keys. The following API keys are available for testing:

| User     | Username  | API Key                                  | Role      |
|----------|-----------|------------------------------------------|-----------|
| Admin    | admin     | 7a4ed5c91b405d30fda60909dbc86c2651c38217 | Admin     |
| Test User| testuser  | 3e9b7b22b84a26e7e95b3d73b6e65f6c3fe6e3f0 | Reporter  |
| Developer| developer | f91c59b0d78f2a10d9b7ea3c631d9f2cbba94f8f | Developer |
| Manager  | manager   | 5c98f85a9f2e34c3b217758e910e196c7a77bf5b | Manager   |

An example `credentials.yaml` file with these keys is provided in `credentials.yaml.example`. For development, you can copy this file to `credentials.yaml` and use the predefined API keys.

## Using Node Labels in credentials.yaml

For better organization, you can use node labels in your credentials.yaml file to identify which API key belongs to which user:

```yaml
# Redmine URL
redmine_url: http://localhost:3000

# API Keys with node labels
admin:
  redmine_api_key: 7a4ed5c91b405d30fda60909dbc86c2651c38217

testuser:
  redmine_api_key: 3e9b7b22b84a26e7e95b3d73b6e65f6c3fe6e3f0

# Default user to use
default_user: admin
```

This format helps other developers understand which key is associated with which user and role.

## Purpose

The credentials file serves the following purposes:

1. **Validation Testing**: During development, we use these credentials to validate that our MCP server can correctly connect to and interact with the Redmine API.
2. **Integration Testing**: The credentials enable automated integration tests against a real Redmine instance.
3. **Reference Configuration**: The file serves as a reference for the required credentials in different environments.

## Security Considerations

The `credentials.yaml` file contains sensitive information and should be handled securely:

1. **Never commit real credentials to version control**. The `.gitignore` file should exclude `credentials.yaml`.
2. **Use environment variables in production** rather than this file.
3. **Limit access permissions** on the file to only the users who need it.
4. **Rotate API keys** regularly according to your security policy.
5. **The predefined API keys are for development only** and should not be used in production.

## Usage in Validation Scripts

The validation scripts use the credentials.yaml file to verify API connectivity:

1. The `scripts/validation/validate_redmine_api.rb` script reads this file to test connection to the Redmine API.
2. The `scripts/validate_environment.sh` script uses this file as part of overall environment validation.

Example usage of the validation script:

```bash
# Run with default options
ruby scripts/validation/validate_redmine_api.rb

# Run with verbose output
ruby scripts/validation/validate_redmine_api.rb -v

# Run with a specific credentials file
ruby scripts/validation/validate_redmine_api.rb -c /path/to/credentials.yaml
```

## Creating Your Own Credentials File

To create your own credentials file:

1. Copy the `credentials.yaml.example` file to `credentials.yaml`
2. For development, you can use the predefined API keys
3. For production, get your Redmine API key from your Redmine profile page
4. Set the correct URL for your Redmine instance

## Troubleshooting

If you encounter validation errors related to credentials:

1. Verify that the API key is valid and has not expired
2. Ensure the Redmine URL is accessible from your environment
3. Check that the Redmine user associated with the API key has sufficient permissions
4. Confirm that the API is enabled in your Redmine instance

## Integration with CI/CD

For CI/CD environments, we recommend:

1. Storing the credentials as environment variables in your CI/CD system
2. Generating the credentials.yaml file during the build process
3. Using test-specific credentials with limited permissions

## Related Files

- `credentials.yaml.example`: Example credentials file with predefined API keys
- `redmine-server/`: Development environment with predefined users and API keys
- `scripts/validation/validate_redmine_api.rb`: Ruby script for validating Redmine API connectivity
- `scripts/validate_environment.sh`: Overall environment validation script
- `.gitignore`: Should include an entry for credentials.yaml

## Process Notes

Following our project principles:

1. **Process Over Speed**: Always validate credentials before proceeding with development tasks
2. **Security Through Repetition**: Consistently follow secure credential handling practices
3. **Documentation First**: Document any credential changes before implementation
4. **Evidence-Based Progress**: Include credential validation evidence in task validation

Remember: How slowly you work is an indication of how careful you are, especially when dealing with credentials and security-related matters.
