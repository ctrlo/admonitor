-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/5/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/4/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE sshlogin DROP FOREIGN KEY sshlogin_fk_host_id;

;
DROP TABLE sshlogin;

;

COMMIT;

