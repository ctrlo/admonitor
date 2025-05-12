-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/15/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/14/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE alarm_message CHANGE COLUMN group_id group_id integer NOT NULL;

;
ALTER TABLE host DROP FOREIGN KEY host_fk_group_id;

;
ALTER TABLE host ADD CONSTRAINT host_fk_group_id FOREIGN KEY (group_id) REFERENCES `group` (id);

;

COMMIT;

