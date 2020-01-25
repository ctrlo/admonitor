-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/8/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE sshlogin DROP FOREIGN KEY sshlogin_fk_user_id,
                     DROP INDEX sshlogin_idx_user_id,
                     DROP COLUMN user_id,
                     DROP COLUMN fingerprint;

;
ALTER TABLE user DROP COLUMN notify_all_ssh;

;
ALTER TABLE fingerprint DROP FOREIGN KEY fingerprint_fk_user_id;

;
DROP TABLE fingerprint;

;

COMMIT;

