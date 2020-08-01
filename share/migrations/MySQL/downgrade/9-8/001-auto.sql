-- Convert schema '/usr/home/tom/checkouts/admonitor/share/migrations/_source/deploy/9/001-auto.yml' to '/usr/home/tom/checkouts/admonitor/share/migrations/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE `host_alarm` DROP FOREIGN KEY `host_alarm_fk_host`;

;
DROP TABLE `host_alarm`;

;

COMMIT;

