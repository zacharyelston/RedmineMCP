#!/bin/bash
# Simple shell script to check Docker container status

echo "Checking Docker container status..."
docker ps

echo -e "\nTesting Redmine API connectivity..."
cd /projects/Desktop/RedmineMCP && python scripts/bootstrap_redmine_simple.py

echo -e "\nDone!"
