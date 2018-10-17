-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/4/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/5/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "sshlogin" (
  "id" serial NOT NULL,
  "host_id" integer NOT NULL,
  "username" character varying(50) NOT NULL,
  "source_ip" character varying(50) NOT NULL,
  "datetime" timestamp NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "sshlogin_idx_host_id" on "sshlogin" ("host_id");

;
ALTER TABLE "sshlogin" ADD CONSTRAINT "sshlogin_fk_host_id" FOREIGN KEY ("host_id")
  REFERENCES "host" ("id") DEFERRABLE;

;

COMMIT;

