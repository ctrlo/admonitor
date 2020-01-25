-- Convert schema '/srv/admonitor/share/migrations/_source/deploy/6/001-auto.yml' to '/srv/admonitor/share/migrations/_source/deploy/7/001-auto.yml':;

;
BEGIN;

;
ALTER TABLE statval ADD INDEX statval_idx_datetime (datetime),
                    ADD INDEX statval_idx_host_datetime (host, datetime);

;

COMMIT;

