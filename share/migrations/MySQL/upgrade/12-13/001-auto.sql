-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/12/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/13/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE host ADD COLUMN silenced smallint NOT NULL DEFAULT 0;

;

COMMIT;

