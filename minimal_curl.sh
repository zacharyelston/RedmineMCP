#!/bin/sh

curl -X POST \
  'http://localhost:3000/projects.json' \
  -H 'Content-Type: application/json' \
  -H 'X-Redmine-API-Key: d775369e8258a39cb774c23af78de43e10452b1c' \
  -d '{"project":{"name":"RedmineMCP","identifier":"redminemcp","description":"MCP Extension for Redmine","is_public":true}}'
