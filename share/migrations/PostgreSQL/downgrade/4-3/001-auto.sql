-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/4/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/3/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE host DROP CONSTRAINT host_fk_group_id;

;
DROP INDEX host_idx_group_id;

;
ALTER TABLE host DROP COLUMN group_id;

;
DROP TABLE group CASCADE;

;
DROP TABLE user_group CASCADE;

;

COMMIT;

