#!/bin/bash
cd /usr/src/redmine
echo "Running tracker creation script..."
bundle exec rails runner create_trackers.rb
echo "Tracker script completed!"
exit 0
