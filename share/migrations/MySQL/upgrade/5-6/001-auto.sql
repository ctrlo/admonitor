-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/5/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/6/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE statval ADD COLUMN string text NULL;

;

COMMIT;

