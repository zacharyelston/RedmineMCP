#!/bin/bash
# check_redmine.sh
# Script to check Redmine container's health and status
# Part of the ModelContextProtocol (MCP) Implementation

echo "This script would check and restart the Redmine container."
echo "It would execute the following operations:"
echo "1. Check if Redmine container is running"
echo "2. Check if Redmine web application is responding"
echo "3. Check database connection from Redmine container"
echo "4. Restart the Redmine container to reload configuration"

echo ""
echo "To resolve the issue with http://localhost:3000/trackers, try these steps manually:"
echo "1. Restart the Redmine container:"
echo "   docker restart redmine-app"
echo ""
echo "2. If that doesn't work, check the logs:"
echo "   docker logs redmine-app"
echo ""
echo "3. You might need to flush the Rails cache. Try running:"
echo "   docker exec -it redmine-app bash -c \"cd /usr/src/redmine && bundle exec rake tmp:cache:clear RAILS_ENV=production\""
echo ""
echo "The error is likely due to one of these reasons:"
echo "- The application cache needs to be cleared after adding trackers"
echo "- There's a missing field or invalid setting in the tracker configuration"
echo "- The Redmine container needs to be restarted to recognize the new database changes"
