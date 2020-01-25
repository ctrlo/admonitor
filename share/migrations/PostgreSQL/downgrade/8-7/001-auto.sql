-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/8/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE sshlogin DROP CONSTRAINT sshlogin_fk_user_id;

;
DROP INDEX sshlogin_idx_user_id;

;
ALTER TABLE sshlogin DROP COLUMN user_id;

;
ALTER TABLE sshlogin DROP COLUMN fingerprint;

;
ALTER TABLE user DROP COLUMN notify_all_ssh;

;
DROP TABLE fingerprint CASCADE;

;

COMMIT;

