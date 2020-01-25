-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/7/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/8/001-auto.yml':;

;
BEGIN;

;
CREATE TABLE "fingerprint" (
  "id" serial NOT NULL,
  "user_id" integer NOT NULL,
  "fingerprint" character varying(64) NOT NULL,
  PRIMARY KEY ("id")
);
CREATE INDEX "fingerprint_idx_user_id" on "fingerprint" ("user_id");

;
ALTER TABLE "fingerprint" ADD CONSTRAINT "fingerprint_fk_user_id" FOREIGN KEY ("user_id")
  REFERENCES "user" ("id") DEFERRABLE;

;
ALTER TABLE sshlogin ADD COLUMN user_id integer;

;
ALTER TABLE sshlogin ADD COLUMN fingerprint character varying(64) NOT NULL;

;
CREATE INDEX sshlogin_idx_user_id on sshlogin (user_id);

;
ALTER TABLE sshlogin ADD CONSTRAINT sshlogin_fk_user_id FOREIGN KEY (user_id)
  REFERENCES user (id) DEFERRABLE;

;
ALTER TABLE user ADD COLUMN notify_all_ssh smallint DEFAULT 0 NOT NULL;

;

COMMIT;

