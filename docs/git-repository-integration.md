# Git Repository Integration with Redmine

This document explains how to mount a local git repository to the Redmine server to enable repository functionality within Redmine projects.

## Overview

Integrating a git repository with Redmine allows for:
- Browsing the repository code directly from Redmine
- Viewing commit history
- Linking issues to specific commits using commit references
- Tracking development progress through repository activity

## Configuration Steps

### 1. Configure Docker Volume Mounting

Modify your Docker setup to mount the local git repository into the Redmine container:

1. Locate your local git repository on your host machine
2. Update the `docker-compose.yml` file to include a volume mount for this repository:

```yaml
version: '3'
services:
  redmine:
    # Existing configuration...
    volumes:
      - redmine-files:/usr/src/redmine/files
      - redmine-plugins:/usr/src/redmine/plugins
      # Add this line to mount your local git repository
      - /path/to/your/local/repo:/usr/src/redmine/repositories/your-repo-name
```

### 2. Configure Redmine to Recognize the Repository

After mounting the repository, configure Redmine to use it:

1. Log in to Redmine as an administrator
2. Navigate to your project settings
3. Select the "Repositories" tab
4. Click "New repository"
5. Select "Git" as the SCM (Source Control Management)
6. In the "Path to repository" field, enter: `/usr/src/redmine/repositories/your-repo-name`
7. Click "Create" to save the repository configuration

### 3. Ensure Proper Permissions

Set the correct permissions for the repository to ensure Redmine can access it:

```bash
# On your host machine
chmod -R 755 /path/to/your/local/repo
```

### 4. Advanced Configuration for Active Development

For active development environments, consider these additional steps:

#### Set Up Auto-Update

1. In the repository settings, enable the "Auto-fetch commits" option
2. Configure the fetch interval based on your development pace

#### Implement a Post-Commit Hook

Create a post-commit hook in your git repository to notify Redmine of changes:

1. Create a file named `.git/hooks/post-commit` in your repository:
```bash
#!/bin/sh
curl -s http://redmine:3000/sys/fetch_changesets?key=your-api-key&id=your-project-identifier
```

2. Make it executable:
```bash
chmod +x .git/hooks/post-commit
```

### 5. Docker Permissions Consideration

Ensure proper permissions between the Docker container and your host system:

```bash
# Find the user ID of the www-data user in the container
docker exec redmine-container id www-data

# Adjust the ownership of your repository
chown -R your-user:your-group /path/to/your/local/repo
chmod -R g+r /path/to/your/local/repo
```

## Troubleshooting

Common issues and solutions:

- **Repository not visible**: Verify the path inside the container matches the path specified in Redmine
- **Permission denied errors**: Check file permissions and ownership
- **Changes not reflecting**: Manually trigger a repository update in Redmine or verify your post-commit hook

## Benefits of Repository Integration

- **Traceability**: Direct links between issues and code changes
- **Visibility**: Team members can browse code without needing git access
- **Integration**: Combines project management and source control in one interface
