-- Convert schema '/usr/home/tom/checkouts/admonitor/share/migrations/_source/deploy/10/001-auto.yml' to '/usr/home/tom/checkouts/admonitor/share/migrations/_source/deploy/9/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "user" DROP COLUMN "web_enabled";

;
DROP TABLE "alarm_message" CASCADE;

;

COMMIT;

