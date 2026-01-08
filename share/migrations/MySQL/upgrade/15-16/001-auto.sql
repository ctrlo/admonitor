-- Convert schema '/home/abeverley/git/admonitor/bin/../share/migrations/_source/deploy/15/001-auto.yml' to '/home/abeverley/git/admonitor/bin/../share/migrations/_source/deploy/16/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE alarm_message CHANGE COLUMN plugin plugin varchar(50) NULL;

;

COMMIT;

