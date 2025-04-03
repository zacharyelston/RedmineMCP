# Redmine Server Interaction Guide

This guide provides optimized commands for interacting with the Redmine server at localhost:3000.

## Authentication

For all commands, use the API key: 
```
d775369e8258a39cb774c23af78de43e10452b1c
```

## Basic Commands

### View All Projects
```
curl -s 'http://localhost:3000/projects.json?key=d775369e8258a39cb774c23af78de43e10452b1c'
```

### View RedmineMCP Project Issues
```
curl -s 'http://localhost:3000/projects/1/issues.json?key=d775369e8258a39cb774c23af78de43e10452b1c'
```

### View agent-topics Project Issues
```
curl -s 'http://localhost:3000/projects/2/issues.json?key=d775369e8258a39cb774c23af78de43e10452b1c'
```

## Creating Content

### Create New Issue
```
curl -X POST 'http://localhost:3000/issues.json?key=d775369e8258a39cb774c23af78de43e10452b1c' -H 'Content-Type: application/json' -d '{"issue":{"project_id":1,"subject":"Title Here","description":"Description here","tracker_id":2}}'
```

### Create New Version
```
curl -X POST 'http://localhost:3000/projects/1/versions.json?key=d775369e8258a39cb774c23af78de43e10452b1c' -H 'Content-Type: application/json' -d '{"version":{"name":"Version Name","status":"open","sharing":"none","description":"Version description"}}'
```

### Create Wiki Page
```
curl -X PUT 'http://localhost:3000/projects/1/wiki/PageName.json?key=d775369e8258a39cb774c23af78de43e10452b1c' -H 'Content-Type: application/json' -d '{"wiki_page":{"text":"Wiki content in Textile format"}}'
```

## Updating Content

### Update Issue
```
curl -X PUT 'http://localhost:3000/issues/ISSUE_ID.json?key=d775369e8258a39cb774c23af78de43e10452b1c' -H 'Content-Type: application/json' -d '{"issue":{"subject":"New Title","description":"New description"}}'
```

### Assign Issue to Version
```
curl -X PUT 'http://localhost:3000/issues/ISSUE_ID.json?key=d775369e8258a39cb774c23af78de43e10452b1c' -H 'Content-Type: application/json' -d '{"issue":{"fixed_version_id":VERSION_ID}}'
```

### Update Status
```
curl -X PUT 'http://localhost:3000/issues/ISSUE_ID.json?key=d775369e8258a39cb774c23af78de43e10452b1c' -H 'Content-Type: application/json' -d '{"issue":{"status_id":STATUS_ID}}'
```
Status IDs: 1=New, 2=In Progress, 3=Resolved, 5=Closed

## Common IDs Reference

### Projects
- RedmineMCP: ID 1
- agent-topics: ID 2

### Versions (RedmineMCP)
- Phase 1: Research and Planning: ID 1
- Phase 2: Core Implementation: ID 2
- Phase 3: Testing and Enhancement: ID 3
- Phase 4: Deployment and Handover: ID 4

### Trackers
- Bug: ID 1
- Feature: ID 2
- Support: ID 3

Use these commands with single quotes around URLs and double quotes within JSON payloads to avoid parsing issues.
