-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/7/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/6/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE statval DROP INDEX statval_idx_datetime,
                    DROP INDEX statval_idx_host_datetime;

;

COMMIT;

