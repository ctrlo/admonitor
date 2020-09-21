-- Convert schema '/usr/home/tom/checkouts/admonitor/share/migrations/_source/deploy/9/001-auto.yml' to '/usr/home/tom/checkouts/admonitor/share/migrations/_source/deploy/10/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "alarm_message" (
  "id" serial NOT NULL,
  "group_id" integer NOT NULL,
  "message_suffix" text NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "alarm_message_idx_group_id" on "alarm_message" ("group_id");

;
ALTER TABLE "alarm_message" ADD CONSTRAINT "alarm_message_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "group" ("id") DEFERRABLE;

;
ALTER TABLE "user" ADD COLUMN "web_enabled" boolean DEFAULT '0' NOT NULL;

;

COMMIT;

