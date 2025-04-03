#!/bin/sh

curl -X POST \
  'http://localhost:3000/projects.json' \
  -H 'Content-Type: application/json' \
  -H 'X-Redmine-API-Key: d775369e8258a39cb774c23af78de43e10452b1c' \
  -d '{"project":{"name":"RedmineMCP","identifier":"redminemcp","description":"A sophisticated Model Context Protocol (MCP) extension for Redmine that revolutionizes issue management through intelligent AI-driven automation and intuitive user interactions.","is_public":true}}'
