-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/13/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/12/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE host DROP COLUMN silenced;

;

COMMIT;

