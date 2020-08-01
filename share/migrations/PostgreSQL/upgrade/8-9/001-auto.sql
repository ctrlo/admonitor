-- Convert schema '/usr/home/tom/checkouts/admonitor/share/migrations/_source/deploy/8/001-auto.yml' to '/usr/home/tom/checkouts/admonitor/share/migrations/_source/deploy/9/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "host_alarm" (
  "id" serial NOT NULL,
  "stattype" character varying(50) NOT NULL,
  "host" integer DEFAULT 0 NOT NULL,
  "plugin" character varying(50) NOT NULL,
  "decimal" numeric(10,3) NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "host_alarm_idx_host" on "host_alarm" ("host");

;
ALTER TABLE "host_alarm" ADD CONSTRAINT "host_alarm_fk_host" FOREIGN KEY ("host")
  REFERENCES "host" ("id") DEFERRABLE;

;

COMMIT;

