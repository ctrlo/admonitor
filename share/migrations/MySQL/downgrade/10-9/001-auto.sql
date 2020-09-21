-- Convert schema '/usr/home/tom/checkouts/admonitor/share/migrations/_source/deploy/10/001-auto.yml' to '/usr/home/tom/checkouts/admonitor/share/migrations/_source/deploy/9/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE `user` DROP COLUMN `web_enabled`;

;
ALTER TABLE `alarm_message` DROP FOREIGN KEY `alarm_message_fk_group_id`;

;
DROP TABLE `alarm_message`;

;

COMMIT;

