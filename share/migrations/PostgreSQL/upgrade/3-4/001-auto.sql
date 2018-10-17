-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/3/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/4/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "group" (
  "id" serial NOT NULL,
  "name" character varying(50) NOT NULL,
  PRIMARY KEY ("id")
);

;
CREATE TABLE "user_group" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "group_id" integer NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "user_group_idx_group_id" on "user_group" ("group_id");
CREATE INDEX "user_group_idx_user_id" on "user_group" ("user_id");

;
ALTER TABLE "user_group" ADD CONSTRAINT "user_group_fk_group_id" FOREIGN KEY ("group_id")
  REFERENCES "group" ("id") ON DELETE CASCADE ON UPDATE CASCADE DEFERRABLE;

;
ALTER TABLE "user_group" ADD CONSTRAINT "user_group_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") DEFERRABLE;

;
ALTER TABLE host ADD COLUMN group_id integer;

;
CREATE INDEX host_idx_group_id on host (group_id);

;
ALTER TABLE host ADD CONSTRAINT host_fk_group_id FOREIGN KEY (group_id)
  REFERENCES group (id) DEFERRABLE;

;

COMMIT;

