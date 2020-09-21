-- Convert schema '/usr/home/tom/checkouts/admonitor/share/migrations/_source/deploy/11/001-auto.yml' to '/usr/home/tom/checkouts/admonitor/share/migrations/_source/deploy/10/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE "alarm_message" DROP CONSTRAINT "alarm_message_fk_group_id";

;
ALTER TABLE "alarm_message" DROP COLUMN "plugin";

;
ALTER TABLE "alarm_message" ADD CONSTRAINT "alarm_message_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "group" ("id") DEFERRABLE;

;

COMMIT;

