# GitHub Workflows for Redmine MCP

This directory contains GitHub Actions workflows that mirror the GitLab CI/CD pipeline functionality and keep the GitHub and GitLab repositories synchronized.

## Workflows

### Main CI/CD Pipeline (`main.yml`)

Mirrors the GitLab CI/CD pipeline with the following stages:
- **Install**: Installs Node.js dependencies
- **Lint**: Performs code linting
- **Build**: Builds the TypeScript project
- **Test**: Runs standard tests
- **Test Subproject Creation**: Runs specific tests for subproject creation (manual trigger)

### GitLab Synchronization

Two workflows handle bi-directional synchronization between GitHub and GitLab repositories:

#### Sync to GitLab (`sync-gitlab.yml`)
- Triggers when changes are pushed to main/master branch on GitHub
- Pushes changes to the corresponding GitLab repository

#### Sync from GitLab (`sync-from-gitlab.yml`)
- Runs on a schedule (every 6 hours) or can be triggered manually
- Fetches changes from GitLab and creates a pull request to merge them into GitHub

## Setup Requirements

To use these workflows, you need to configure the following secrets in your GitHub repository:

- `GITLAB_URL`: The URL of your GitLab repository
- `GITLAB_TOKEN`: GitLab Personal Access Token with repository write permissions
- `GITLAB_PROJECT_ID`: Your GitLab project ID
- `SYNC_GITHUB_TOKEN`: GitHub Personal Access Token with workflow and repository permissions

## Usage

The main CI/CD pipeline runs automatically on pushes to main/master and on pull requests.

For the GitLab synchronization:
- GitHub to GitLab sync happens automatically when you push to main/master
- GitLab to GitHub sync runs on schedule or can be triggered manually from the Actions tab

## Manual Triggers

Some workflows support manual triggering:
- To test subproject creation: Go to Actions → Main CI/CD → Run workflow
- To sync from GitLab: Go to Actions → Sync from GitLab → Run workflow
