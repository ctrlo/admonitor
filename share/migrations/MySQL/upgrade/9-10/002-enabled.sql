BEGIN;

-- Will run slowly on installations with large numbers of users
UPDATE user SET web_enabled = '1' WHERE password IS NOT NULL;

COMMIT;
