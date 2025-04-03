#!/bin/bash
curl -X PUT 'http://localhost:3000/projects/1/wiki/ProjectOverview.json?key=d775369e8258a39cb774c23af78de43e10452b1c' \
  -H 'Content-Type: application/json' \
  -d @wiki_content.json
