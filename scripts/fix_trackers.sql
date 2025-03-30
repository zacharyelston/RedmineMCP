SELECT COUNT(*) FROM trackers;
SELECT COUNT(*) FROM trackers WHERE name = 'Bug';

        INSERT INTO trackers (name, description, default_status_id, is_in_roadmap, position)
        SELECT 'Bug', 'Software defects and issues', 1, 0, COALESCE(MAX(position), 0) + 1
        FROM trackers
        WHERE NOT EXISTS (SELECT 1 FROM trackers WHERE name = 'Bug');
        
SELECT COUNT(*) FROM trackers WHERE name = 'Feature';

        INSERT INTO trackers (name, description, default_status_id, is_in_roadmap, position)
        SELECT 'Feature', 'New features and enhancements', 1, 1, COALESCE(MAX(position), 0) + 1
        FROM trackers
        WHERE NOT EXISTS (SELECT 1 FROM trackers WHERE name = 'Feature');
        
SELECT COUNT(*) FROM trackers WHERE name = 'Support';

        INSERT INTO trackers (name, description, default_status_id, is_in_roadmap, position)
        SELECT 'Support', 'Support requests and questions', 1, 0, COALESCE(MAX(position), 0) + 1
        FROM trackers
        WHERE NOT EXISTS (SELECT 1 FROM trackers WHERE name = 'Support');
        
SELECT * FROM trackers;
