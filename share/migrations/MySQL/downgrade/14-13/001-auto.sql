-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/14/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/13/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE host DROP COLUMN collect_agents;

;

COMMIT;

